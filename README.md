# Llama 3.3 70B JARVIS 프로젝트
Llama 3.3 70B Abliterated + 한국어 QLoRA. 터미널 채팅용.


## 1. 새 Pod 열었을 때 (venv가 Network Volume에 있으면 금방 끝남)
cd /workspace && curl -sL https://raw.githubusercontent.com/mastalji/llama-project/master/init_setup.sh | bash


## 1-1. 모델 다운로드 (1회)
cd /workspace/llama-project
huggingface-cli login
./download_model.sh


## 1-2. 학습 (1회)
cd /workspace/llama-project
source venv/bin/activate
./run_train.sh


## 2. 대화 (추론)
**터미널 1: 서버** (GPU 로딩 막대 표시됨)
cd /workspace/llama-project
source venv/bin/activate
pip install -r requirements-inference.txt   # vLLM (1회)
./run_server.sh

**터미널 2: 채팅**
cd /workspace/llama-project
./chat.sh

종료: `quit` / `exit` / `q`






## 추가 명령어
| 작업 | 명령어 |
|------|--------|
| venv 활성화 | `source venv/bin/activate` |
| 코드만 pull | `cd /workspace/llama-project && git pull` |
| 학습만 (데이터 이미 있으면) | `./run_train.sh` (env 자동 전환 포함) |
| 데이터만 준비 | `python scripts/prepare_dataset.py` |
---

## 문제 해결
**run_server 시 `ModuleNotFoundError: flex_attention`**  
→ `pip install --upgrade torchao` 후 재실행

---

## 환경 변수
```bash
export HF_HOME=/workspace/.cache/huggingface
export WORKSPACE=/workspace    # init_setup, download_model 경로
```