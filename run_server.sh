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
echo ""

# vLLM 백그라운드 실행 (로그는 파일로)
VLLM_LOG="${PROJECT_DIR}/.vllm.log"
if [ -d "$ADAPTER_PATH" ] && [ -f "$ADAPTER_PATH/adapter_config.json" ]; then
  vllm serve "$BASE_MODEL" --enable-lora --lora-modules "default=$ADAPTER_PATH" \
    --port "$PORT" --max-model-len "$MAX_LEN" --gpu-memory-utilization 0.9 \
    > "$VLLM_LOG" 2>&1 &
else
  vllm serve "$BASE_MODEL" --port "$PORT" --max-model-len "$MAX_LEN" --gpu-memory-utilization 0.9 \
    > "$VLLM_LOG" 2>&1 &
fi
VLLM_PID=$!

cleanup() {
  kill $VLLM_PID 2>/dev/null && echo -e "\n서버 종료됨."
  exit 0
}
trap cleanup INT TERM

# GPU 로딩 막대 (서버 준비될 때까지)
WIDTH=40
while true; do
  read -r used total <<< $(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | tr ',' ' ')
  used=${used//[ ,]/}
  total=${total//[ ,]/}
  [ -z "$used" ] && used=0
  [ -z "$total" ] && total=1

  pct=$((used * 100 / total))
  filled=$((WIDTH * used / total))
  empty=$((WIDTH - filled))
  bar=$(printf "%${filled}s" | tr ' ' '█')
  bar+=$(printf "%${empty}s" | tr ' ' '░')

  printf "\r  [%s] %3d%%  %s / %s MB  " "$bar" "$pct" "$used" "$total"

  kill -0 $VLLM_PID 2>/dev/null || { echo -e "\n\nvLLM 프로세스 종료됨. 로그: $VLLM_LOG"; exit 1; }
  curl -s "http://localhost:$PORT/v1/models" >/dev/null 2>&1 && break
  sleep 2
done

echo -e "\n\n  ✓ 서버 준비됨. ./chat.sh 로 대화하세요.\n"
wait $VLLM_PID
