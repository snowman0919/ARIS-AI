#!/usr/bin/env python3
from __future__ import annotations

import importlib
import platform
import subprocess
import sys


def version(module_name: str) -> str:
    try:
        module = importlib.import_module(module_name)
    except Exception as exc:  # noqa: BLE001
        return f"not available ({exc.__class__.__name__}: {exc})"
    return getattr(module, "__version__", "installed")


def run(cmd: list[str]) -> str:
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.STDOUT).strip()
    except Exception as exc:  # noqa: BLE001
        return f"not available ({exc})"


print("DGX Spark AI Lab host environment")
print(f"Python: {sys.version.split()[0]} ({sys.executable})")
print(f"Platform: {platform.platform()} / {platform.machine()}")
print(f"NVIDIA SMI: {run(['nvidia-smi', '--query-gpu=name,driver_version', '--format=csv,noheader'])}")

for name in ["numpy", "scipy", "pandas", "sklearn", "matplotlib", "cv2", "mujoco", "gymnasium"]:
    print(f"{name}: {version(name)}")

try:
    import torch

    print(f"torch: {torch.__version__}")
    print(f"torch.cuda.is_available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        device = torch.device("cuda:0")
        capability = torch.cuda.get_device_capability(device)
        print(f"cuda device: {torch.cuda.get_device_name(device)} capability={capability}")
        x = torch.randn((2048, 2048), device=device)
        y = x @ x.T
        torch.cuda.synchronize()
        print(f"torch matmul smoke test: {tuple(y.shape)}")
except Exception as exc:  # noqa: BLE001
    print(f"torch: not available ({exc.__class__.__name__}: {exc})")
