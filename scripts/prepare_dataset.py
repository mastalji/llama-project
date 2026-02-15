#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
한국어 QLoRA 학습용 데이터셋 준비
- heegyu/open-korean-instructions에서 ShareGPT 제외
- Axolotl chat_template 형식(conversations)으로 변환
"""

import json
import re
import os
from pathlib import Path

def parse_open_korean_text(text: str) -> list[dict]:
    """
    open-korean-instructions 형식 파싱:
    <|user|>, <|bot|>, <|sys|> 토큰으로 구분 → Axolotl conversations 형식
    """
    role_map = {"user": "human", "bot": "assistant", "sys": "system"}
    conversations = []

    # 1) <|user|>, <|bot|>, <|sys|> 명시적 토큰 패턴
    pattern = r'<\|(user|bot|sys)\|>\s*\n?(.*?)(?=<\|(?:user|bot|sys)\|>|$)'
    matches = re.findall(pattern, text, re.DOTALL)
    if matches:
        for role_raw, content in matches:
            content = content.strip()
            if not content:
                continue
            role = role_map.get(role_raw, "human")
            conversations.append({"from": role, "value": content})

    # 2) 파싱 실패 시: instruction\\nresponse (KoAlpaca 싱글턴)
    if not conversations and "\n" in text:
        lines = text.strip().split("\n")
        if len(lines) >= 2:
            first = lines[0].strip()
            rest = "\n".join(lines[1:]).strip()
            if len(first) > 5 and len(rest) > 5:
                conversations = [
                    {"from": "human", "value": first},
                    {"from": "assistant", "value": rest}
                ]

    return conversations


def main():
    from datasets import load_dataset
    
    base = Path(os.environ.get("PROJECT_DIR", ".")).resolve()
    data_dir = base / "data"
    data_dir.mkdir(parents=True, exist_ok=True)
    output_path = data_dir / "korean_instructions_uncensored.jsonl"
    
    print("데이터셋 로드: heegyu/open-korean-instructions ...")
    ds = load_dataset("heegyu/open-korean-instructions", split="train")
    
    print("ShareGPT 필터링 중...")
    def filter_sharegpt(example):
        src = str(example.get("source", "")).lower()
        return "sharegpt" not in src
    
    ds = ds.filter(filter_sharegpt)
    print(f"필터 후 샘플 수: {len(ds)}")
    
    count = 0
    with open(output_path, "w", encoding="utf-8") as f:
        for ex in ds:
            text = ex.get("text", "")
            if not text or not text.strip():
                continue
            convs = parse_open_korean_text(text)
            if not convs:
                continue
            line = json.dumps({"conversations": convs}, ensure_ascii=False)
            f.write(line + "\n")
            count += 1
    
    print(f"저장 완료: {output_path}")
    print(f"총 {count}개 샘플")


if __name__ == "__main__":
    main()
