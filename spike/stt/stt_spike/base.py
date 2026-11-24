"""Tipe data bersama, kontrak provider, dan helper polling."""
from __future__ import annotations

import time
from dataclasses import dataclass, field
from typing import Callable, Iterable


@dataclass
class Utterance:
    speaker: str
    start_ms: int
    end_ms: int
    text: str


@dataclass
class TranscriptResult:
    provider: str
    utterances: list[Utterance]
    processing_seconds: float = 0.0
    raw: dict = field(default_factory=dict)

    @property
    def speakers(self) -> list[str]:
        return sorted({u.speaker for u in self.utterances})

    @property
    def text(self) -> str:
        return " ".join(u.text for u in self.utterances)


class ProviderError(RuntimeError):
    pass


class Provider:
    """Kontrak yang sama dengan TranscriptionProvider di app iOS nanti."""

    name = "base"
    env_key = ""

    def __init__(self, api_key: str, language: str = "id", max_speakers: int | None = None):
        self.api_key = api_key
        self.language = language
        self.max_speakers = max_speakers

    def transcribe(self, audio_path: str) -> TranscriptResult:
        raise NotImplementedError


def check_response(resp, context: str) -> None:
    if resp.status_code >= 400:
        raise ProviderError(f"{context} gagal ({resp.status_code}): {resp.text[:500]}")


def poll(
    fetch: Callable[[], tuple[str, dict]],
    done: set[str],
    failed: set[str],
    label: str,
    interval: float = 10.0,
    timeout: float = 4 * 3600,
    sleep: Callable[[float], None] = time.sleep,
) -> dict:
    """Panggil fetch() berulang sampai status masuk done atau failed."""
    waited = 0.0
    last_status = None
    while waited <= timeout:
        status, payload = fetch()
        if status != last_status:
            print(f"[{label}] status: {status}", flush=True)
            last_status = status
        if status in done:
            return payload
        if status in failed:
            raise ProviderError(f"[{label}] job gagal: {payload}")
        sleep(interval)
        waited += interval
    raise ProviderError(f"[{label}] timeout setelah {timeout / 60:.0f} menit")


@dataclass
class Token:
    speaker: str
    start_ms: int
    end_ms: int
    text: str
    no_space_before: bool = False


def merge_tokens(tokens: Iterable[Token]) -> list[Utterance]:
    """Gabungkan token berurutan dari speaker yang sama menjadi satu utterance."""
    utterances: list[Utterance] = []
    for tok in tokens:
        piece = tok.text if tok.no_space_before else " " + tok.text.lstrip()
        if utterances and utterances[-1].speaker == tok.speaker:
            last = utterances[-1]
            last.text += piece
            last.end_ms = max(last.end_ms, tok.end_ms)
        else:
            utterances.append(Utterance(tok.speaker, tok.start_ms, tok.end_ms, piece))
    for u in utterances:
        u.text = " ".join(u.text.split())
    return utterances
