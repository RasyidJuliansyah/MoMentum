# Meeting Summary iOS

> Memori proyek untuk Claude Code. Jaga di bawah ±200 baris. Kalau ada detail panjang, taruh di `docs/` lalu tautkan ke sini, jangan disalin.

## Ringkasan
- Tujuan produk: app iOS untuk merekam meeting tatap muka lalu membuat transkrip per speaker, ringkasan, action items, dan MoM dalam Bahasa Indonesia.
- Pengguna utama: pemilik proyek (pemakaian pribadi). Arsitektur disiapkan agar bisa dibuka ke publik.
- Status: Fase 1 (MVP app iOS). Spike vendor STT dilewati (lihat di bawah). PRD: `PRD_MoMentum.md`.

## Tech stack & arsitektur
- App iOS: Swift + SwiftUI (`MoMentum/`, Xcode project). Storage lokal: SwiftData.
- Spike Python (`spike/stt/`) dipertahankan sebagai referensi pola kode, bukan lagi jalur keputusan vendor.
- Vendor STT: AssemblyAI (dipilih langsung, tanpa run spike pembanding — lihat `docs/architecture.md` untuk risiko yang diterima).
- Semua panggilan STT/LLM lewat provider adapter (`Provider` di spike, `TranscriptionProvider`/`SummaryProvider` di app) supaya vendor bisa diganti dan nanti dipindah ke backend proxy.
- Struktur folder app (`MoMentum/MoMentum/`):
  - `Models/` schema SwiftData (Meeting, Segment, Utterance, ActionItem)
  - `Services/` AudioRecorder, TranscriptionProvider, SummaryProvider, KeychainStore
  - `Views/` layar UI per fitur
- Detail arsitektur: lihat `docs/architecture.md`

## Perintah
- Spike (opsional, referensi saja): `cd spike/stt && python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`
- App iOS: buka `MoMentum/MoMentum.xcodeproj` di Xcode, build & run lewat simulator/perangkat.
- Tes unit: `xcodebuild test -project MoMentum/MoMentum.xcodeproj -scheme MoMentum -destination 'platform=iOS Simulator,name=<SIM>' -only-testing:MoMentumTests`. Sesi UI memakai `iPhone 17`, sesi Logic (Cline, worktree `../meeting-summary-ios-logic`) memakai `iPhone 18 Pro`, supaya build dan data tidak saling timpa.
- Lint/format: _isi setelah ditentukan (SwiftLint/SwiftFormat belum dipasang)_

## Konvensi kode
- Satu file satu tanggung jawab. File yang sudah ratusan baris dipecah.
- Penamaan: camelCase untuk fungsi/properti, PascalCase untuk tipe/struct/class/komponen SwiftUI.
- Error ditangani di layer Services, bukan di View.

## Testing
- Target `MoMentumTests` (unit) dan `MoMentumUITests` sudah ada di project Xcode, pakai itu untuk tes baru.
- Setiap fitur baru datang bersama tes dasarnya.
- Bug diperbaiki dengan menulis tes yang gagal dulu.

## Git workflow
- Branch: `feat/<nama>`, `fix/<nama>`, `chore/<nama>`
- Commit kecil setelah setiap tugas yang lolos tes. Format: `feat(scope): deskripsi`
- Jangan push ke `main` tanpa review.

## Keamanan
- Rahasia hanya di `.env` (tidak di-commit). Contoh variabel ada di `.env.example`.
- Jangan pernah menulis API key, password, atau token di file ini.

## Jangan lakukan
- Jangan menambah dependency baru tanpa menyebutkan alasannya.
- Jangan mengubah file di `docs/` tanpa diminta.
- Jangan menulis API key di kode Swift atau Python. Spike membaca `.env`, app membaca Keychain.
- Jangan commit rekaman meeting atau hasil transkrip (berisi suara dan data orang lain).
