#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="${DGX_LAB_VENV:-$ROOT_DIR/.venv}"
MODE="${1:-base}"

case "$MODE" in
  base|ai|physics|all) ;;
  *)
    echo "Usage: $0 [base|ai|physics|all]" >&2
    exit 2
    ;;
esac

python3 -m venv "$VENV_DIR"
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

python -m pip install --upgrade pip setuptools wheel
python -m pip install -r "$ROOT_DIR/requirements/base.txt"

if [[ "$MODE" == "ai" || "$MODE" == "all" ]]; then
  python -m pip install -r "$ROOT_DIR/requirements/ai-cu130.txt"
fi

if [[ "$MODE" == "physics" || "$MODE" == "all" ]]; then
  python -m pip install -r "$ROOT_DIR/requirements/physics.txt"
fi

python -m ipykernel install --user --name dgx-spark-ai-lab --display-name "DGX Spark AI Lab"
python "$ROOT_DIR/scripts/verify_host_env.py"
