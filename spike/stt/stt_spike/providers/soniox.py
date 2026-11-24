"""Soniox async REST API: upload file, buat transcription, polling, ambil token.

PERLU DICEK: endpoint dan nama model ditulis dari ingatan dan halaman SDK,
belum dari halaman referensi resmi. Jika error, cocokkan dengan
https://soniox.com/docs lalu ubah SONIOX_MODEL atau path di bawah.
"""
from __future__ import annotations

import os
import time

import requests

from ..base import Provider, Token, TranscriptResult, check_response, merge_tokens, poll

BASE_URL = os.getenv("SONIOX_BASE_URL", "https://api.soniox.com/v1")
MODEL = os.getenv("SONIOX_MODEL", "stt-async-v4")


def tokens_to_utterances(tokens: list[dict]):
    return merge_tokens(
        Token(
            speaker=str(t.get("speaker") or "?"),
            start_ms=int(t.get("start_ms") or 0),
            end_ms=int(t.get("end_ms") or 0),
            text=t.get("text", ""),
            # Token Soniox sudah membawa spasi di depannya bila perlu.
            no_space_before=True,
        )
        for t in tokens
    )


class SonioxProvider(Provider):
    name = "soniox"
    env_key = "SONIOX_API_KEY"

    def transcribe(self, audio_path: str) -> TranscriptResult:
        headers = {"Authorization": f"Bearer {self.api_key}"}
        started = time.monotonic()

        with open(audio_path, "rb") as f:
            resp = requests.post(
                f"{BASE_URL}/files", headers=headers,
                files={"file": (os.path.basename(audio_path), f)}, timeout=1800,
            )
        check_response(resp, "Soniox upload")
        file_id = resp.json()["id"]

        body = {
            "model": MODEL,
            "file_id": file_id,
            "language_hints": [self.language],
            "enable_speaker_diarization": True,
        }
        resp = requests.post(f"{BASE_URL}/transcriptions", headers=headers, json=body, timeout=60)
        check_response(resp, "Soniox create transcription")
        transcription_id = resp.json()["id"]

        def fetch():
            r = requests.get(f"{BASE_URL}/transcriptions/{transcription_id}", headers=headers, timeout=60)
            check_response(r, "Soniox polling")
            data = r.json()
            return data.get("status", "unknown"), data

        poll(fetch, {"completed"}, {"error"}, label=self.name)
        resp = requests.get(f"{BASE_URL}/transcriptions/{transcription_id}/transcript", headers=headers, timeout=120)
        check_response(resp, "Soniox ambil transcript")
        data = resp.json()
        utterances = tokens_to_utterances(data.get("tokens") or [])

        # Bersihkan file dan transkrip di server Soniox. Gagal di sini tidak fatal.
        for path in (f"transcriptions/{transcription_id}", f"files/{file_id}"):
            try:
                requests.delete(f"{BASE_URL}/{path}", headers=headers, timeout=30)
            except requests.RequestException:
                pass

        return TranscriptResult(self.name, utterances, time.monotonic() - started, data)
