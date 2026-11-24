"""AssemblyAI pre-recorded API: upload, buat job, polling, ambil utterances.

Endpoint dan field mengikuti dokumentasi resmi (dicek 24 Nov 2026):
https://www.assemblyai.com/docs/pre-recorded-audio/label-speakers.md
"""
from __future__ import annotations

import os
import time

import requests

from ..base import Provider, TranscriptResult, Utterance, check_response, poll

BASE_URL = os.getenv("ASSEMBLYAI_BASE_URL", "https://api.assemblyai.com")


class AssemblyAIProvider(Provider):
    name = "assemblyai"
    env_key = "ASSEMBLYAI_API_KEY"

    def transcribe(self, audio_path: str) -> TranscriptResult:
        headers = {"authorization": self.api_key}
        started = time.monotonic()

        with open(audio_path, "rb") as f:
            resp = requests.post(f"{BASE_URL}/v2/upload", headers=headers, data=f, timeout=1800)
        check_response(resp, "AssemblyAI upload")
        upload_url = resp.json()["upload_url"]

        body = {"audio_url": upload_url, "speaker_labels": True, "language_code": self.language}
        if self.max_speakers:
            body["speaker_options"] = {"max_speakers_expected": self.max_speakers}
        models = os.getenv("ASSEMBLYAI_SPEECH_MODELS")
        if models:
            body["speech_models"] = [m.strip() for m in models.split(",") if m.strip()]

        resp = requests.post(f"{BASE_URL}/v2/transcript", headers=headers, json=body, timeout=60)
        check_response(resp, "AssemblyAI create transcript")
        transcript_id = resp.json()["id"]

        def fetch():
            r = requests.get(f"{BASE_URL}/v2/transcript/{transcript_id}", headers=headers, timeout=60)
            check_response(r, "AssemblyAI polling")
            data = r.json()
            return data["status"], data

        # Batas polling 60 request per menit per transkrip, jadi interval 10 detik aman.
        data = poll(fetch, {"completed"}, {"error"}, label=self.name)
        utterances = [
            Utterance(str(u["speaker"]), int(u["start"]), int(u["end"]), u["text"])
            for u in data.get("utterances") or []
        ]
        return TranscriptResult(self.name, utterances, time.monotonic() - started, data)
