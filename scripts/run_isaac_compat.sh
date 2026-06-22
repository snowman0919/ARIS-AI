#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISAAC_ROOT="$ROOT_DIR/docker/isaac-sim"
IMAGE="${ISAAC_SIM_IMAGE:-nvcr.io/nvidia/isaac-sim:5.1.0}"

mkdir -p \
  "$ISAAC_ROOT/cache/main/ov" \
  "$ISAAC_ROOT/cache/main/warp" \
  "$ISAAC_ROOT/cache/computecache" \
  "$ISAAC_ROOT/config" \
  "$ISAAC_ROOT/data/documents" \
  "$ISAAC_ROOT/data/Kit" \
  "$ISAAC_ROOT/logs" \
  "$ISAAC_ROOT/pkg"

if command -v sudo >/dev/null 2>&1; then
  sudo chown -R 1234:1234 "$ISAAC_ROOT" || true
fi

exec docker run --rm -it \
  --name isaac-sim-compat \
  --gpus all \
  --network=host \
  -e ACCEPT_EULA=Y \
  -e PRIVACY_CONSENT=N \
  -v "$ISAAC_ROOT/cache/main:/isaac-sim/.cache:rw" \
  -v "$ISAAC_ROOT/cache/computecache:/isaac-sim/.nv/ComputeCache:rw" \
  -v "$ISAAC_ROOT/logs:/isaac-sim/.nvidia-omniverse/logs:rw" \
  -v "$ISAAC_ROOT/config:/isaac-sim/.nvidia-omniverse/config:rw" \
  -v "$ISAAC_ROOT/data:/isaac-sim/.local/share/ov/data:rw" \
  -v "$ISAAC_ROOT/pkg:/isaac-sim/.local/share/ov/pkg:rw" \
  -u 1234:1234 \
  --entrypoint bash \
  "$IMAGE" \
  -lc "./isaac-sim.compatibility_check.sh --/app/quitAfter=10 --no-window"
