#!/usr/bin/env bash
set -euo pipefail

echo "== System =="
uname -a
id
echo

echo "== GPU =="
nvidia-smi || true
echo

echo "== Docker CLI =="
docker --version || true
docker compose version || true
echo

echo "== Docker access =="
if docker info >/tmp/dgx-lab-docker-info 2>/tmp/dgx-lab-docker-error; then
  echo "Docker socket access: OK"
  echo "Docker runtimes:"
  docker info --format '{{json .Runtimes}}'
else
  echo "Docker socket access: FAILED"
  cat /tmp/dgx-lab-docker-error
  echo
  echo "Run this once from an admin shell, then log out and back in:"
  echo "  sudo usermod -aG docker $USER"
  echo
fi

echo "== NVIDIA Container Toolkit =="
if command -v nvidia-container-cli >/dev/null 2>&1; then
  nvidia-container-cli --version
else
  echo "nvidia-container-cli is not installed"
fi
echo

echo "== GPU container smoke test =="
echo "Run after Docker access works:"
echo "  docker run --rm --gpus all nvcr.io/nvidia/cuda:13.0.1-devel-ubuntu24.04 nvidia-smi"
