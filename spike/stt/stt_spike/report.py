"""Simpan hasil per provider (JSON + Markdown) dan tabel ringkasan."""
from __future__ import annotations

import json
from dataclasses import asdict
from pathlib import Path

from .base import TranscriptResult


def fmt_time(ms: int) -> str:
    s = ms // 1000
    return f"{s // 3600:02d}:{s % 3600 // 60:02d}:{s % 60:02d}"


def transcript_markdown(result: TranscriptResult, audio_name: str) -> str:
    lines = [
        f"# {result.provider} · {audio_name}",
        "",
        f"Speaker terdeteksi: {len(result.speakers)} ({', '.join(result.speakers) or '-'})",
        f"Waktu proses: {result.processing_seconds / 60:.1f} menit",
        "",
    ]
    for u in result.utterances:
        lines.append(f"**[{fmt_time(u.start_ms)}] Speaker {u.speaker}:** {u.text}")
        lines.append("")
    return "\n".join(lines)


def save_result(result: TranscriptResult, out_dir: Path, audio_name: str) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"{result.provider}.md").write_text(transcript_markdown(result, audio_name), encoding="utf-8")
    payload = {
        "provider": result.provider,
        "processing_seconds": result.processing_seconds,
        "speakers": result.speakers,
        "utterances": [asdict(u) for u in result.utterances],
        "raw": result.raw,
    }
    (out_dir / f"{result.provider}.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8"
    )


def summary_markdown(rows: list[dict], audio_name: str) -> str:
    lines = [
        f"# Ringkasan spike STT · {audio_name}",
        "",
        "| Provider | Status | Waktu proses (menit) | Speaker | Utterance | Kata | WER |",
        "| --- | --- | --- | --- | --- | --- | --- |",
    ]
    for r in rows:
        wer_text = f"{r['wer']:.1%}" if r.get("wer") is not None else "-"
        lines.append(
            f"| {r['provider']} | {r['status']} | {r.get('minutes', '-')} | {r.get('speakers', '-')} "
            f"| {r.get('utterances', '-')} | {r.get('words', '-')} | {wer_text} |"
        )
    lines += [
        "",
        "## Penilaian manual (isi sendiri, skala 1 sampai 5)",
        "",
        "| Provider | Ketepatan speaker | Istilah kerja & nama | Angka & tanggal | Catatan |",
        "| --- | --- | --- | --- | --- |",
    ]
    lines += [f"| {r['provider']} |  |  |  |  |" for r in rows]
    return "\n".join(lines) + "\n"
