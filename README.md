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

**run_server 시 `ImportError: flash_attn_2_cuda ... undefined symbol`**  
→ flash-attn이 추론용 torch와 맞지 않음.

**해결**: 아래 중 하나 실행 (환경: Python 3.11, torch 2.9, CUDA 12.8 기준)
```bash
# 1) 사전 빌드 wheel - 1분 내 설치 (권장)
pip install https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/download/v0.7.16/flash_attn-2.8.3+cu128torch2.9-cp311-cp311-linux_x86_64.whl

# 2) 소스 빌드 - 15~30분 소요
pip install flash-attn --no-build-isolation --upgrade --force-reinstall
```
Python/CUDA/torch 버전이 다르면 [flashattn.dev](https://flashattn.dev/) 또는 [mjun0812 packages](https://github.com/mjun0812/flash-attention-prebuild-wheels/blob/main/doc/packages.md)에서 맞는 wheel 찾아서 위처럼 `pip install <URL>` 로 설치.

---

## 환경 변수
```bash
export HF_HOME=/workspace/.cache/huggingface
export WORKSPACE=/workspace    # init_setup, download_model 경로
```