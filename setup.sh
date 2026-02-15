#!/bin/bash
# ============================================================
# [AI를 사람으로 만들기] RunPod 환경 자동 세팅 스크립트
# H100 / Network Volume(/workspace) 환경 기준
# ============================================================

set -e

echo "[1/7] 시스템 확인..."
nvidia-smi || { echo "nvidia-smi 실패. GPU 환경인지 확인하세요."; exit 1; }
python3 --version || { echo "Python3 필요"; exit 1; }

# 작업 경로: Network Volume 우선
WORKSPACE="${WORKSPACE:-/workspace}"
PROJECT_DIR="${PROJECT_DIR:-$WORKSPACE/llama-project}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "[2/7] 가상환경 생성..."
VENV_DIR="${PROJECT_DIR}/venv"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
source "$VENV_DIR/bin/activate"

echo "[3/7] pip 업그레이드..."
pip install -U packaging setuptools wheel ninja

echo "[4/7] PyTorch (CUDA 12.x) 설치..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

echo "[5/7] 기본 의존성 설치..."
[ -f "$SCRIPT_DIR/requirements.txt" ] && pip install -r "$SCRIPT_DIR/requirements.txt" || pip install -r requirements.txt

echo "[6/7] Axolotl 설치 (flash-attn, deepspeed)..."
pip install --no-build-isolation "axolotl[flash-attn,deepspeed]"

echo "[7/7] 완료"

echo ""
echo "============================================"
echo "환경 세팅 완료."
echo "활성화: source $VENV_DIR/bin/activate"
echo "============================================"
