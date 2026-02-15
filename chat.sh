#!/bin/bash
# chat.py 실행 (venv 활성화)
cd "$(dirname "$0")"
[ -d venv ] && source venv/bin/activate
python chat.py "$@"
