"""Jalankan beberapa vendor STT pada file audio yang sama lalu bandingkan hasilnya.

Contoh:
    python -m stt_spike.cli ~/Downloads/meeting.m4a
    python -m stt_spike.cli sample-5menit.m4a --reference sample-5menit.txt --max-speakers 6
"""
from __future__ import annotations

import argparse
import os
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from .providers import PROVIDERS
from .report import save_result, summary_markdown
from .wer import wer


def load_dotenv(*paths: Path) -> None:
    """Baca KEY=VALUE dari file .env tanpa menimpa env yang sudah ada."""
    for path in paths:
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def run_one(name: str, audio: Path, args, reference: str | None) -> dict:
    cls = PROVIDERS[name]
    api_key = os.getenv(cls.env_key)
    if not api_key:
        print(f"[{name}] dilewati: {cls.env_key} belum diisi di .env")
        return {"provider": name, "status": "dilewati (tanpa key)"}
    try:
        result = cls(api_key, language=args.language, max_speakers=args.max_speakers).transcribe(str(audio))
    except Exception as exc:  # noqa: BLE001 - spike: tampilkan error apa pun lalu lanjut ke vendor lain
        print(f"[{name}] ERROR: {exc}")
        return {"provider": name, "status": f"error: {str(exc)[:80]}"}

    save_result(result, Path(args.out) / audio.stem, audio.name)
    row = {
        "provider": name,
        "status": "ok",
        "minutes": f"{result.processing_seconds / 60:.1f}",
        "speakers": len(result.speakers),
        "utterances": len(result.utterances),
        "words": len(result.text.split()),
    }
    if reference:
        row["wer"] = wer(reference, result.text)
    print(f"[{name}] selesai: {row}")
    return row


def main() -> None:
    parser = argparse.ArgumentParser(description="Bandingkan vendor STT untuk rekaman meeting Bahasa Indonesia")
    parser.add_argument("audio", nargs="+", help="File rekaman (m4a, mp3, wav)")
    parser.add_argument("--providers", nargs="+", choices=sorted(PROVIDERS), default=sorted(PROVIDERS))
    parser.add_argument("--language", default="id", help="Kode bahasa, default id (Bahasa Indonesia)")
    parser.add_argument("--max-speakers", type=int, default=None, help="Batas atas jumlah speaker (opsional)")
    parser.add_argument("--reference", help="Transkrip manual (.txt) untuk menghitung WER. Hanya untuk satu file audio.")
    parser.add_argument("--out", default="results", help="Folder hasil (default: results/)")
    args = parser.parse_args()

    here = Path(__file__).resolve()
    load_dotenv(Path.cwd() / ".env", here.parents[1] / ".env", here.parents[3] / ".env")

    if args.reference and len(args.audio) > 1:
        parser.error("--reference hanya bisa dipakai dengan satu file audio")
    reference = Path(args.reference).read_text(encoding="utf-8") if args.reference else None

    for audio_arg in args.audio:
        audio = Path(audio_arg).expanduser()
        if not audio.is_file():
            print(f"File tidak ditemukan: {audio}")
            continue
        print(f"\n=== {audio.name} ===")
        with ThreadPoolExecutor(max_workers=len(args.providers)) as pool:
            rows = list(pool.map(lambda n: run_one(n, audio, args, reference), args.providers))
        out_dir = Path(args.out) / audio.stem
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / "summary.md").write_text(summary_markdown(rows, audio.name), encoding="utf-8")
        print(f"Ringkasan: {out_dir / 'summary.md'}")


if __name__ == "__main__":
    main()
