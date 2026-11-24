# Handover: Pembagian Kerja UI ↔ Logic

Versi 24 Nov 2026. Dua sesi Claude Code jalan paralel di project yang sama:
- **Sesi UI** (Figma MCP tersambung): bangun layar sesuai `docs/design-handoff.md`.
- **Sesi Logic** (sesi ini): bangun `Models/` dan `Services/` sesuai `PRD_MoMentum.md` dan `docs/architecture.md`.

Dokumen ini jembatan supaya dua sesi gak saling tabrak dan UI bisa bind ke logic tanpa nunggu logic selesai dulu.

## 1. Pembagian wilayah file

| Folder | Pemilik | Catatan |
| --- | --- | --- |
| `MoMentum/MoMentum/Views/` | Sesi UI | Semua layar (`HomeView`, `RecordingView`, dst sesuai tabel layar di `design-handoff.md` bagian 8) |
| `MoMentum/MoMentum/DesignSystem/` | Sesi UI | `Colors.swift`, `Backgrounds.swift`, komponen visual (bagian 5), `MeetingStatus+Style.swift` |
| `MoMentum/MoMentum/Models/` | Sesi Logic | SwiftData models: `Meeting`, `Segment`, `Utterance`, `ActionItem` |
| `MoMentum/MoMentum/Services/` | Sesi Logic | `AudioRecorder`, `TranscriptionProvider` (+ implementasi AssemblyAI), `SummaryProvider`, `KeychainStore`, `RecordingConstants` |
| `MoMentumApp.swift` | Bersama | Sesi Logic daftar `@Model` schema & `.environment(...)` service. Sesi UI jangan hapus baris itu saat edit `WindowGroup`/scene. |

Jangan edit folder milik sesi lain tanpa koordinasi dulu — biar gak conflict pas merge.

## 2. Konvensi integrasi (View ↔ Service)

- Tiap service = `@Observable final class`, didaftarkan di `MoMentumApp.swift` lewat `.environment(myService)`.
- View mengakses lewat `@Environment(AudioRecorder.self) private var recorder`, dst — pola sama seperti `@Environment(\.modelContext)` yang sudah dipakai di `ContentView.swift`.
- Data model (SwiftData) tetap lewat `@Environment(\.modelContext)` + `@Query`, tidak berubah.
- Service belum tentu lengkap saat UI mulai dibangun — View boleh pakai data dummy/preview dulu, tinggal ganti ke service asli belakangan karena nama & signature sudah dikunci di bagian 3.

## 3. Kontrak nama (jangan didefinisikan ulang di sisi UI)

Sudah ada (buatan sesi logic, pakai langsung):
- `Meeting`, `Segment`, `Utterance`, `ActionItem` — `Models/`
- `MeetingStatus` enum, 5 case: `.recorded`, `.queued`, `.processing`, `.done`, `.failed`. UI tinggal `extension` di `DesignSystem/MeetingStatus+Style.swift` untuk `.label`/`.colors` sesuai `design-handoff.md` bagian 7. **Jangan bikin enum status baru.**
- `TranscriptionProvider` protocol — `Services/TranscriptionProvider.swift`
- `KeychainStore` (enum, static methods `set`/`get`/`delete`) — `Services/KeychainStore.swift`
- `RecordingConstants.segmentDuration` — `Services/RecordingConstants.swift`

Menyusul dari sesi logic (nama final, belum ada isinya):
- `AudioRecorder` — `@Observable`, expose state rekam/jeda/durasi/level audio untuk `WaveformView`
- `SummaryProvider` — protocol adapter LLM, sepadan pola `TranscriptionProvider`

## 4. Status progres

| Item | Status |
| --- | --- |
| SwiftData models (Meeting/Segment/Utterance/ActionItem) | Selesai |
| `TranscriptionProvider` protocol | Selesai (skeleton, belum ada implementasi AssemblyAI) |
| `KeychainStore` | Selesai, ada test |
| `RecordingConstants` | Selesai |
| `AudioRecorder` | Belum |
| Implementasi AssemblyAI di `TranscriptionProvider` | Belum |
| Penyatuan label speaker antarsegmen | Belum |
| `SummaryProvider` (LLM) | Belum |
| Queue offline + retry | Belum |
| `Views/`, `DesignSystem/` | Belum (sesi UI) |

Update tabel ini manual tiap ada item selesai — bukan otomatis.

## 5. Referensi
- `PRD_MoMentum.md` — requirement produk
- `docs/architecture.md` — keputusan arsitektur (vendor STT, storage, dll)
- `docs/design-handoff.md` — spec desain, token, daftar layar, node Figma
