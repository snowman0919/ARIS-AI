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

  sim_log=/tmp/aris_lidar_sim_stack.log
  lidar_log=/tmp/aris_lidar_sim_node.log
  cloud_log=/tmp/aris_scan_cloud_once.log

  timeout -s INT 10s ros2 launch aris_vehicle_sim pure_sim.launch.py >"$sim_log" 2>&1 &
  sim_pid=$!
  sleep 2

  timeout -s INT 8s ros2 launch aris_vehicle_sim lidar_sim.launch.py >"$lidar_log" 2>&1 &
  lidar_pid=$!
  sleep 2

  code=0
  timeout 5s ros2 topic echo --once /scan_cloud >"$cloud_log" 2>&1 || code=$?

  kill -INT "$lidar_pid" >/dev/null 2>&1 || true
  kill -INT "$sim_pid" >/dev/null 2>&1 || true
  wait "$lidar_pid" || true
  wait "$sim_pid" || true

  if [[ "$code" != "0" ]]; then
    echo "ERROR: /scan_cloud PointCloud2 sample was not published by lidar_sim_node."
    echo "--- sim log ---"
    sed -n "1,180p" "$sim_log"
    echo "--- lidar log ---"
    sed -n "1,180p" "$lidar_log"
    echo "--- cloud echo ---"
    sed -n "1,160p" "$cloud_log"
    exit "$code"
  fi

  python3 - <<PY
from pathlib import Path
text = Path("/tmp/aris_scan_cloud_once.log").read_text()
for key in ["height:", "width:", "point_step:", "fields:"]:
    print(next(line for line in text.splitlines() if line.strip().startswith(key)))
PY
'
