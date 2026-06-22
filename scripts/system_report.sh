#!/usr/bin/env bash
set -euo pipefail

echo "== OS =="
lsb_release -a 2>/dev/null || cat /etc/os-release
uname -a
echo

echo "== CPU and memory =="
lscpu | sed -n '1,35p'
free -h
df -h / /home
echo

echo "== NVIDIA =="
nvidia-smi
nvcc --version 2>/dev/null || true
echo

echo "== Python =="
python3 --version
python3 -m pip --version
echo

echo "== Docker =="
docker --version || true
docker compose version || true
docker info --format '{{json .Runtimes}}' 2>/dev/null || true
