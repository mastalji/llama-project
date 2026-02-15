#!/bin/bash
# vLLM API 서버 실행
# chat.py에서 대화할 때 필요. 나중에 프론트 붙여도 같은 API 사용

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

BASE_MODEL="${BASE_MODEL:-huihui-ai/Llama-3.3-70B-Instruct-abliterated}"
ADAPTER_PATH="$PROJECT_DIR/outputs/qlora-70b-ko"
PORT="${LLM_PORT:-8000}"
MAX_LEN="${MAX_MODEL_LEN:-4096}"

WORKSPACE="${WORKSPACE:-/workspace}"
CACHE="$WORKSPACE/.cache/huggingface"
[ -d "$CACHE" ] && export HF_HOME="$CACHE" TRANSFORMERS_CACHE="$CACHE"

[ -d "$PROJECT_DIR/venv" ] && source "$PROJECT_DIR/venv/bin/activate"

command -v vllm &>/dev/null || { echo "vllm 설치: pip install vllm"; exit 1; }

echo "모델: $BASE_MODEL | 포트: $PORT"
echo "대화: python chat.py (또는 ./chat.sh)"

if [ -d "$ADAPTER_PATH" ] && [ -f "$ADAPTER_PATH/adapter_config.json" ]; then
  exec vllm serve "$BASE_MODEL" --enable-lora --lora-modules "default=$ADAPTER_PATH" \
    --port "$PORT" --max-model-len "$MAX_LEN" --gpu-memory-utilization 0.9
else
  exec vllm serve "$BASE_MODEL" --port "$PORT" --max-model-len "$MAX_LEN" --gpu-memory-utilization 0.9
fi
