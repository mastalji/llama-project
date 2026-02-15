#!/bin/bash
# ============================================================
# 학습된 LoRA 어댑터로 추론 (vLLM 예시)
# ============================================================

set -e

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BASE_MODEL="huihui-ai/Llama-3.3-70B-Instruct-abliterated"
ADAPTER_PATH="${PROJECT_DIR}/outputs/qlora-70b-ko"

# vLLM으로 서버 실행 (LoRA 어댑터 로드)
# 참고: vLLM은 --enable-lora 로 LoRA 어댑터 지원
vllm serve "$BASE_MODEL" \
  --enable-lora \
  --lora-modules "default=${ADAPTER_PATH}" \
  --max-model-len 4096 \
  --gpu-memory-utilization 0.9

# 또는 Ollama 사용 시:
# 1. 베이스 모델 + LoRA merge 후 GGUF 변환
# 2. ollama create 로 모델 등록
# inference_params.yaml 참고하여 temperature 등 설정
