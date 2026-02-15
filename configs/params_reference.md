# 파라미터 참고 (plans_extracted.txt 기반)

## LoRA 학습 파라미터 (configs/qlora_70b_ko.yaml에서 조정)

| 파라미터 | 현재값 | 권장범위 | 설명 |
|---------|--------|----------|------|
| lora_r | 64 | 32~64 | 높을수록 미세 표현 학습, 용량↑ |
| lora_alpha | 128 | Rank×2 | 학습 안정성 |
| learning_rate | 0.0001 | 2e-4~5e-5 | 너무 높으면 기존 지능 파괴 |
| micro_batch_size | 2 | 4~8 (H100) | VRAM에 맞게 |
| num_epochs | 2 | 1~3 | 과하면 앵무새화 |
| sequence_len | 4096 | 4096~8192 | 긴 맥락 필요 시 |
| warmup_ratio | 0.1 | 10% | 학습 초기 적응 |
| weight_decay | 0.01 | - | 과적합 방지 |

## 추론 파라미터 (inference_params.yaml)

| 파라미터 | 값 | 효과 |
|---------|-----|------|
| temperature | 0.7~0.8 | 낮으면 논리적, 높으면 창의적 |
| top_p | 0.9 | 문맥에 맞는 단어 선택 |
| top_k | 40~50 | 엉뚱한 단어 차단 |
| repetition_penalty | 1.1~1.15 | "죄송합니다" 반복 방지 |
| frequency_penalty | 0.1~0.3 | 로봇 느낌 제거 |
| presence_penalty | 0.1~0.2 | 대화 풍성하게 |

## Logit Bias (금기어/선호어)

- **Negative Bias**: "죄송합니다", "인공지능" → -100
- **Positive Bias**: "사유", "공생" → +5.0
