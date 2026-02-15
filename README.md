# [AI를 사람으로 만들기] Llama 3.3 70B JARVIS 프로젝트

Llama 3.3 70B Abliterated를 한국어 능력 강화한 개인 비서(JARVIS 스타일)로 만드는 프로젝트.

**저장소:** https://github.com/mastalji/llama-project

---

## 1. 처음 서버 들어갔을 때 (RunPod H100)

### 1) 초기 설정 (1회 또는 Pod 새로 만들 때마다)

```bash
cd /workspace
curl -sL https://raw.githubusercontent.com/mastalji/llama-project/master/init_setup.sh | bash
```

또는 이미 clone 했다면:

```bash
cd /workspace/llama-project
./init_setup.sh
```

`init_setup.sh`가 하는 일: **git clone** → **환경 세팅** (venv, PyTorch, Axolotl 등)  
약 10~20분 소요.

### 2) 모델 다운로드 (1회성)

```bash
cd /workspace/llama-project
huggingface-cli login
./download_model.sh
```

모델(~140GB)을 `/workspace/.cache/huggingface`에 저장. Pod 종료해도 Network Volume에 남음.

### 3) 학습 실행

```bash
cd /workspace/llama-project
source venv/bin/activate
./run_train.sh
```

데이터 준비 → QLoRA 학습 자동 실행.

---

## 2. 전체 흐름

| 순서 | 작업 | 스크립트 | 1회성 | Pod 재시작 시 |
|:----:|------|----------|:-----:|:-------------:|
| 1 | 초기 설정 (clone + env) | `init_setup.sh` | × | ○ |
| 2 | 모델 다운로드 | `download_model.sh` | ○ | × |
| 3 | 학습 | `run_train.sh` | × | × |

---

## 3. pip 설치 순서

`pip install -r requirements.txt`만으로는 안 됨. `setup.sh`(또는 `init_setup.sh`)가 올바른 순서로 설치함:

1. `pip install -U packaging setuptools wheel ninja`
2. **PyTorch (CUDA) 먼저**
3. `pip install -r requirements.txt`
4. `pip install --no-build-isolation axolotl[flash-attn,deepspeed]`

---

## 4. 디렉터리 구조

| 경로 | 설명 |
|------|------|
| `init_setup.sh` | **초기 전체 설정** (git clone + pip/venv/Axolotl 등) |
| `download_model.sh` | **LLM 모델 다운로드** (1회성, ~140GB) |
| `setup.sh` | 환경 세팅만 (venv, PyTorch, Axolotl) |
| `run_train.sh` | 데이터 준비 + QLoRA 학습 |
| `scripts/prepare_dataset.py` | 한국어 데이터셋 준비 (ShareGPT 제외) |
| `configs/qlora_70b_ko.yaml` | QLoRA 학습 설정 |
| `inference_params.yaml` | 추론 파라미터 |
| `data/` | 데이터셋 (자동 생성) |
| `outputs/` | LoRA 어댑터 출력 |

---

## 5. 주요 파라미터

| 항목 | 값 | 설명 |
|------|-----|------|
| base_model | huihui-ai/Llama-3.3-70B-Instruct-abliterated | 무검열 베이스 |
| lora_r | 64 | LoRA Rank |
| lora_alpha | 128 | Rank×2 |
| sequence_len | 4096 | 컨텍스트 길이 |
| num_epochs | 2 | 학습 반복 |
| learning_rate | 0.0001 | 학습률 |

조정: `configs/qlora_70b_ko.yaml`, `configs/params_reference.md`

---

## 6. 환경 변수 (모델 캐시)

```bash
export HF_HOME=/workspace/.cache/huggingface
export TRANSFORMERS_CACHE=/workspace/.cache/huggingface
```

`run_train.sh`가 자동 설정. `~/.bashrc`에 넣어두면 편함.

---

## 7. 수동 실행

```bash
python scripts/prepare_dataset.py   # 데이터만 준비
axolotl train configs/qlora_70b_ko.yaml  # 학습만
```

---

## 8. 학습 완료 후

- LoRA 어댑터: `outputs/qlora-70b-ko/`
- vLLM, Ollama로 베이스 + 어댑터 로드
- `inference_params.yaml`, `scripts/run_inference.sh` 참고
