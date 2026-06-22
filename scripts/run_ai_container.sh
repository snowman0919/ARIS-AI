#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${DGX_PYTORCH_IMAGE:-nvcr.io/nvidia/pytorch:26.04-py3}"
PORT="${JUPYTER_PORT:-8888}"
TOKEN="${JUPYTER_TOKEN:-dgx-spark}"

mkdir -p "$ROOT_DIR"/{workspaces,notebooks,models,data}

exec docker run --rm -it \
  --gpus all \
  --ipc=host \
  --ulimit memlock=-1 \
  --ulimit stack=67108864 \
  -p "$PORT:8888" \
  -v "$ROOT_DIR/workspaces:/workspace/dgx:rw" \
  -v "$ROOT_DIR/notebooks:/workspace/notebooks:rw" \
  -v "$ROOT_DIR/models:/models:rw" \
  -v "$ROOT_DIR/data:/data:rw" \
  -w /workspace/dgx \
  "$IMAGE" \
  bash -lc "python - <<'PY'
import torch
print('torch', torch.__version__)
print('cuda available', torch.cuda.is_available())
if torch.cuda.is_available():
    print(torch.cuda.get_device_name(0), torch.cuda.get_device_capability(0))
PY
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.token='$TOKEN'"
