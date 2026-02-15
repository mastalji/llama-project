#!/bin/bash
# ============================================================
# [AI를 사람으로 만들기] QLoRA 학습 실행 스크립트
# 1. 환경 활성화 2. 데이터 준비 3. 학습 실행
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$SCRIPT_DIR}"
cd "$PROJECT_DIR"

echo "프로젝트 경로: $PROJECT_DIR"

# 모델 캐시 (Network Volume 활용)
export HF_HOME="${HF_HOME:-/workspace/.cache/huggingface}"
export TRANSFORMERS_CACHE="${TRANSFORMERS_CACHE:-$HF_HOME}"
export HUGGINGFACE_HUB_CACHE="${HUGGINGFACE_HUB_CACHE:-$HF_HOME}"

# 1. venv 활성화
VENV_DIR="${PROJECT_DIR}/venv"
if [ -d "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
else
    echo "venv 없음. 먼저 ./setup.sh 를 실행하세요."
    exit 1
fi

# 2. 학습용 환경으로 전환 (Axolotl 호환)
echo "학습용 환경으로 전환 중..."
pip install torch==2.5.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 -q
pip install -r "${PROJECT_DIR}/requirements-training.txt" -q

# 3. 학습 종료 시 추론용으로 복구
restore_inference() {
    echo ""
    echo "추론용 환경으로 복구 중..."
    pip install -r "${PROJECT_DIR}/requirements-inference.txt" -q
    echo "복구 완료."
}
trap restore_inference EXIT

# 4. 데이터 준비 (없을 경우)
DATA_FILE="${PROJECT_DIR}/data/korean_instructions_uncensored.jsonl"
if [ ! -f "$DATA_FILE" ]; then
    echo "데이터셋 준비 중..."
    export PROJECT_DIR="$PROJECT_DIR"
    python "$PROJECT_DIR/scripts/prepare_dataset.py"
else
    echo "데이터셋 이미 존재: $DATA_FILE"
fi

# 5. 학습 실행
CONFIG="${PROJECT_DIR}/configs/qlora_70b_ko.yaml"
echo "학습 시작. 설정: $CONFIG"
echo "출력: ${PROJECT_DIR}/outputs/qlora-70b-ko"
echo ""

axolotl train "$CONFIG"

echo ""
echo "학습 완료. LoRA 어댑터: ${PROJECT_DIR}/outputs/qlora-70b-ko"
echo "(추론용 환경 자동 복구됨)"
