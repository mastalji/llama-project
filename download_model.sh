#!/bin/bash
# ============================================================
# 모델 다운로드 (1회성) - Network Volume(/workspace)에 저장
# ============================================================

set -e

WORKSPACE="${WORKSPACE:-/workspace}"
CACHE_DIR="${WORKSPACE}/.cache/huggingface"
MODEL_ID="huihui-ai/Llama-3.3-70B-Instruct-abliterated"

echo "캐시 경로: $CACHE_DIR"
echo "모델: $MODEL_ID"
echo ""

export HF_HOME="$CACHE_DIR"
export TRANSFORMERS_CACHE="$CACHE_DIR"
export HUGGINGFACE_HUB_CACHE="$CACHE_DIR"
mkdir -p "$CACHE_DIR"

# huggingface_hub 설치 (없을 경우)
python3 -c "import huggingface_hub" 2>/dev/null || pip install huggingface_hub

echo "Hugging Face 로그인 필요할 수 있음..."
huggingface-cli login 2>/dev/null || true

echo "모델 다운로드 시작 (~140GB, 시간 걸림)..."
python3 -c "
from huggingface_hub import snapshot_download
snapshot_download('$MODEL_ID', cache_dir='$CACHE_DIR')
"
echo ""
echo "완료. 캐시: $CACHE_DIR"
echo "다음에 학습할 때 HF_HOME=$CACHE_DIR 로 설정하면 재다운로드 안 함."
