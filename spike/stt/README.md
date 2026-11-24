# Spike Fase 0: membandingkan vendor STT

Script ini mengirim rekaman meeting yang sama ke AssemblyAI, Soniox, dan Speechmatics, lalu menyimpan transkrip per speaker dari masing-masing vendor supaya bisa dibandingkan. Hasilnya dipakai untuk memilih vendor sebelum masuk ke app iOS (gate A di PRD).

## Status pengecekan API

| Vendor | Sumber kode | Status |
| --- | --- | --- |
| AssemblyAI | Dokumentasi resmi Speaker Diarization, dicek 24 Nov 2026 | Paling bisa dipercaya |
| Soniox | Ingatan dan halaman SDK di PyPI | Perlu dicek jika error. Nama model diatur lewat `SONIOX_MODEL` |
| Speechmatics | Ingatan | Perlu dicek jika error |

Setiap vendor berjalan terpisah. Kalau satu gagal, yang lain tetap jalan dan error-nya tercatat di `summary.md`.

## Persiapan (sekali saja)

1. Buat akun di tiap vendor dan ambil API key. Ketiganya biasanya punya kredit gratis untuk mencoba, tapi besarnya perlu dicek di situs masing-masing.
2. Di root proyek, salin `.env.example` menjadi `.env`, lalu isi key yang sudah ada. Vendor tanpa key akan dilewati.
3. Install dependency:

```bash
cd spike/stt
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
```

## Menjalankan

```bash
# Rekaman meeting penuh, semua vendor
python -m stt_spike.cli ~/Downloads/meeting-senin.m4a

# Cuplikan 5 menit + transkrip manual untuk menghitung WER
python -m stt_spike.cli cuplikan.m4a --reference cuplikan.txt --max-speakers 6

# Hanya satu vendor
python -m stt_spike.cli meeting.m4a --providers assemblyai
```

Hasil tersimpan di `results/<nama-file>/`: transkrip `.md` per vendor, data mentah `.json`, dan `summary.md` berisi tabel perbandingan serta kolom penilaian manual.

## Cara menilai

Saran saya, uji dua jenis rekaman:

- **Cuplikan 5 sampai 10 menit** yang Anda transkrip sendiri dengan teliti, lalu dipakai sebagai `--reference`. Dari sini keluar angka WER (persentase kata yang salah). Semakin kecil semakin baik.
- **2 sampai 3 rekaman meeting penuh** (idealnya ada yang di atas 2 jam). Untuk ini WER tidak praktis, jadi baca hasilnya lalu isi tabel penilaian manual di `summary.md`: apakah pergantian speaker tepat, apakah istilah kerja dan nama orang benar, dan apakah angka serta tanggal tertulis benar.

Catat juga waktu proses dan biaya per jam audio dari dashboard tiap vendor.

## Catatan

- Rekaman iPhone (Voice Memos) biasanya berformat `.m4a`. Kalau ada vendor yang menolak format itu, ubah dulu dengan `ffmpeg -i input.m4a output.mp3`.
- `--max-speakers` bersifat batas keras di AssemblyAI. Isi sedikit di atas jumlah peserta. Untuk Speechmatics, opsi ini belum dipakai.
- Rekaman meeting berisi suara orang lain. Folder `results/` dan file audio sudah dimasukkan ke `.gitignore` supaya tidak ikut ter-commit.
- Struktur `Provider` di sini sengaja dibuat sama dengan `TranscriptionProvider` yang direncanakan untuk app iOS, supaya logikanya bisa dipindah ke Swift.

Tes: `python -m pytest -q`
