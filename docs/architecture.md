# Arsitektur Meeting Summary iOS (MoMentum)

## Stack
- Swift + SwiftUI, target iOS (Xcode project di `MoMentum/`).
- Storage lokal: SwiftData (riwayat meeting, segmen, transkrip, action items).
- Secrets: iOS Keychain (BYOK). Tidak pernah ditulis di kode.

## Struktur folder app (`MoMentum/MoMentum/`)
- `Models/` — schema SwiftData: `Meeting`, `Segment`, `Utterance`, `ActionItem`.
- `Services/` — `AudioRecorder`, `TranscriptionProvider` (adapter STT), `SummaryProvider` (adapter LLM), `KeychainStore`.
- `Views/` — layar UI per fitur (Record, History, MeetingDetail, Settings).

## Keputusan terkunci
- Vendor STT: AssemblyAI (dipilih langsung tanpa run spike pembanding; akurasi Bahasa Indonesia & diarization >2 jam belum diverifikasi — risiko diterima, dicek saat testing nyata Fase 1).
- Segmen rekaman: 15 menit, konstanta yang mudah diubah (bukan hardcoded tersebar).
- Transkrip kasar on-device: ditunda, bukan bagian Fase 1. Keputusan S vs W menyusul setelah M-priority selesai.
- Provider adapter pattern spike Python (`spike/stt/stt_spike/base.py`: `Provider`, `Utterance`, `TranscriptResult`) jadi referensi struktur `TranscriptionProvider` Swift, bukan sumber keputusan vendor lagi.

## Alur data (ringkas)
1. Rekam → segmen 15 menit disimpan lokal (file audio + metadata SwiftData).
2. Tiap segmen dikirim ke AssemblyAI via `TranscriptionProvider`. Hasil per segmen digabung, label speaker antarsegmen disamakan (titik rawan, lihat catatan di PRD).
3. Transkrip final → `SummaryProvider` (LLM) → ringkasan, action items, MoM.
4. Semua hasil ditulis balik ke SwiftData lokal.

