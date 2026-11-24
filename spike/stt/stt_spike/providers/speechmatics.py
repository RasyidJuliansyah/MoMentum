"""Speechmatics batch API: buat job dengan file, polling, ambil transcript json-v2.

PERLU DICEK: endpoint dan format config ditulis dari ingatan, belum dari
halaman referensi resmi. Jika error, cocokkan dengan https://docs.speechmatics.com
"""
from __future__ import annotations

import json
import os
import time

import requests

from ..base import Provider, Token, TranscriptResult, check_response, merge_tokens, poll

BASE_URL = os.getenv("SPEECHMATICS_BASE_URL", "https://asr.api.speechmatics.com/v2")
OPERATING_POINT = os.getenv("SPEECHMATICS_OPERATING_POINT", "enhanced")


def results_to_utterances(results: list[dict]):
    tokens = []
    for item in results:
        alt = (item.get("alternatives") or [{}])[0]
        tokens.append(
            Token(
                speaker=str(alt.get("speaker") or "?"),
                start_ms=int(float(item.get("start_time", 0)) * 1000),
                end_ms=int(float(item.get("end_time", 0)) * 1000),
                text=alt.get("content", ""),
                no_space_before=item.get("type") == "punctuation",
            )
        )
    return merge_tokens(tokens)


class SpeechmaticsProvider(Provider):
    name = "speechmatics"
    env_key = "SPEECHMATICS_API_KEY"

    def transcribe(self, audio_path: str) -> TranscriptResult:
        headers = {"Authorization": f"Bearer {self.api_key}"}
        started = time.monotonic()

        config = {
            "type": "transcription",
            "transcription_config": {
                "language": self.language,
                "diarization": "speaker",
                "operating_point": OPERATING_POINT,
            },
        }
        with open(audio_path, "rb") as f:
            resp = requests.post(
                f"{BASE_URL}/jobs", headers=headers,
                files={"data_file": (os.path.basename(audio_path), f)},
                data={"config": json.dumps(config)}, timeout=1800,
            )
        check_response(resp, "Speechmatics create job")
        job_id = resp.json()["id"]

        def fetch():
            r = requests.get(f"{BASE_URL}/jobs/{job_id}", headers=headers, timeout=60)
            check_response(r, "Speechmatics polling")
            data = r.json()
            return data.get("job", {}).get("status", "unknown"), data

        poll(fetch, {"done"}, {"rejected", "deleted", "expired"}, label=self.name)
        resp = requests.get(
            f"{BASE_URL}/jobs/{job_id}/transcript", headers=headers,
            params={"format": "json-v2"}, timeout=120,
        )
        check_response(resp, "Speechmatics ambil transcript")
        data = resp.json()
        utterances = results_to_utterances(data.get("results") or [])
        return TranscriptResult(self.name, utterances, time.monotonic() - started, data)
