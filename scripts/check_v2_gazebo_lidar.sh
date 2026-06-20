#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
aris_load_env

aris_compose run --rm aris-ros2-dev bash -lc '
  set -euo pipefail
  colcon build --symlink-install
  set +u
  source install/setup.bash
  set -u

  launch_log=/tmp/aris_v2_gazebo_lidar_launch.log
  echo_log=/tmp/aris_v2_scan_cloud_echo.log
  timeout -s INT 16s ros2 launch aris_localization v2_gazebo_lidar.launch.py \
    >"$launch_log" 2>&1 &
  launch_pid=$!
  sleep 6

  code=0
  timeout 7s ros2 topic echo --once /scan_cloud >"$echo_log" 2>&1 || code=$?

  kill -INT "$launch_pid" >/dev/null 2>&1 || true
  wait "$launch_pid" || true

  if [[ "$code" != "0" ]]; then
    echo "BLOCKED: no /scan_cloud PointCloud2 sample from Gazebo gpu_lidar."
    echo "The launch log should show whether the Gazebo create service was unavailable or"
    echo "whether the headless environment failed to activate the GPU rendering sensor."
    echo "--- launch log ---"
    sed -n "1,220p" "$launch_log"
    echo "--- echo log ---"
    sed -n "1,120p" "$echo_log"
    exit 1
  fi

  python3 - <<PY
from pathlib import Path
text = Path("/tmp/aris_v2_scan_cloud_echo.log").read_text()
for key in ["height:", "width:", "fields:"]:
    print(next(line for line in text.splitlines() if line.strip().startswith(key)))
PY
'
