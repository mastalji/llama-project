#!/bin/bash
# vLLM API 서버 실행
# chat.py에서 대화할 때 필요. 나중에 프론트 붙여도 같은 API 사용

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# 기본: abliterated + bitsandbytes (Network Volume에서 140GB 읽어서 느림)
# 빠른 로딩: BASE_MODEL=...-AWQ-4bit QUANTIZATION=awq (40GB만 읽음, 대신 abliterated 아님)
BASE_MODEL="${BASE_MODEL:-huihui-ai/Llama-3.3-70B-Instruct-abliterated}"
QUANTIZATION="${QUANTIZATION:-bitsandbytes}"
ADAPTER_PATH="$PROJECT_DIR/outputs/qlora-70b-ko"
PORT="${LLM_PORT:-8000}"
MAX_LEN="${MAX_MODEL_LEN:-4096}"

WORKSPACE="${WORKSPACE:-/workspace}"
CACHE="$WORKSPACE/.cache/huggingface"
[ -d "$CACHE" ] && export HF_HOME="$CACHE" TRANSFORMERS_CACHE="$CACHE"

[ -d "$PROJECT_DIR/venv" ] && source "$PROJECT_DIR/venv/bin/activate"

# bitsandbytes 70B: 140GB 디스크 읽기. 기본 타임아웃 600초(10분) 부족 시 해제
export VLLM_ENGINE_READY_TIMEOUT_S="${VLLM_ENGINE_READY_TIMEOUT_S:-3600}"

command -v vllm &>/dev/null || { echo "vllm 설치: pip install -r requirements-inference.txt"; exit 1; }

echo "모델: $BASE_MODEL | 양자화: $QUANTIZATION | 포트: $PORT"
echo ""

# vLLM 백그라운드 실행 (로그는 파일로)
VLLM_LOG="${PROJECT_DIR}/.vllm.log"
# H100 1장(80GB): 70B bf16≈140GB라 불가. bitsandbytes=140GB 읽음(느림), awq=40GB 읽음(빠름)
# --enforce-eager: CUDA graph 끔, --gpu-memory-utilization 0.85: 여유 확보
if [ -d "$ADAPTER_PATH" ] && [ -f "$ADAPTER_PATH/adapter_config.json" ]; then
  vllm serve "$BASE_MODEL" --enable-lora --lora-modules "default=$ADAPTER_PATH" \
    --quantization "$QUANTIZATION" --enforce-eager --port "$PORT" --max-model-len "$MAX_LEN" --gpu-memory-utilization 0.85 \
    > "$VLLM_LOG" 2>&1 &
else
  vllm serve "$BASE_MODEL" --quantization "$QUANTIZATION" --enforce-eager --port "$PORT" --max-model-len "$MAX_LEN" --gpu-memory-utilization 0.85 \
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
  bar=$(printf "%${filled}s" | tr ' ' '#')
  bar+=$(printf "%${empty}s" | tr ' ' '-')

  printf "\r  [%s] %3d%%  %s / %s MB  " "$bar" "$pct" "$used" "$total"

  kill -0 $VLLM_PID 2>/dev/null || { echo -e "\n\nvLLM 프로세스 종료됨. 로그: $VLLM_LOG"; exit 1; }
  curl -s "http://localhost:$PORT/v1/models" >/dev/null 2>&1 && break
  sleep 2
done

echo -e "\n\n  ✓ 서버 준비됨. ./chat.sh 로 대화하세요.\n"
wait $VLLM_PID
