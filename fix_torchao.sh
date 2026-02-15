#!/bin/bash
# torchao 0.16.0 + torch 2.9.1+cu128 비호환 → cu128용 nightly wheel로 교체 (1회 실행)
set -e
cd "$(dirname "$0")"
source venv/bin/activate
pkill -f "vllm serve" 2>/dev/null || true
pip install --pre torchao --index-url https://download.pytorch.org/whl/nightly/cu128
echo "완료. ./run_server.sh 실행하세요."
