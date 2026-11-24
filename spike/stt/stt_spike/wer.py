"""Word Error Rate sederhana tanpa dependency tambahan."""
from __future__ import annotations

import re

_PUNCT = re.compile(r"[^\w\s]", re.UNICODE)


def normalize(text: str) -> list[str]:
    return _PUNCT.sub(" ", text.lower()).split()


def wer(reference: str, hypothesis: str) -> float:
    ref, hyp = normalize(reference), normalize(hypothesis)
    if not ref:
        raise ValueError("Teks referensi kosong")
    prev = list(range(len(hyp) + 1))
    for i, r in enumerate(ref, start=1):
        cur = [i] + [0] * len(hyp)
        for j, h in enumerate(hyp, start=1):
            cost = 0 if r == h else 1
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost)
        prev = cur
    return prev[-1] / len(ref)
