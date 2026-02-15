#!/bin/bash
# ============================================================
# 초기 전체 설정 (git clone + 환경 세팅) - 한 번에 실행
# RunPod 서버 처음 들어갔을 때 이것만 실행
# ============================================================

set -e

REPO_URL="https://github.com/mastalji/llama-project.git"
WORKSPACE="${WORKSPACE:-/workspace}"
[ -d "$WORKSPACE" ] || WORKSPACE="$(pwd)"
PROJECT_DIR="${WORKSPACE}/llama-project"

echo "=============================================="
echo "llama-project 초기 설정"
echo "=============================================="

# 1. git clone (없으면) 또는 pull
mkdir -p "$WORKSPACE"
cd "$WORKSPACE"
if [ ! -d "llama-project" ]; then
    echo "[1/2] 저장소 클론..."
    git clone "$REPO_URL" llama-project
else
    echo "[1/2] 저장소 업데이트..."
    cd llama-project && git pull
fi

cd "$PROJECT_DIR"
chmod +x *.sh 2>/dev/null || true

# 2. 환경 세팅
echo "[2/2] 환경 세팅 (venv, PyTorch, Axolotl...)..."
./setup.sh

echo ""
echo "=============================================="
echo "초기 설정 완료."
echo ""
echo "다음 단계:"
echo "  1. 모델 다운로드 (1회): ./download_model.sh"
echo "  2. 학습 실행: source venv/bin/activate && ./run_train.sh"
echo "=============================================="
