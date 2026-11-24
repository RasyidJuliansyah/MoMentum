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

### 3a. Data yang dibutuhkan UI dari sesi Logic

Ditambahkan sesi UI, 24 Nov 2026. Layar di bawah sudah dibangun dengan data sementara. Begitu item ini tersedia, UI tinggal menyambungkan. Nama field boleh berbeda, asal isinya sama; kabari kalau beda.

**`AudioRecorder` → layar 02, 14, 15.** UI membaca satu struct `RecordingSnapshot` (`Views/Recording/RecordingSnapshot.swift`):

| Data | Bentuk | Dipakai untuk |
| --- | --- | --- |
| Judul, agenda | `String`, `String?` | Header layar rekam |
| Fase | merekam / dijeda oleh user / dijeda karena telepon | Titik status, tombol Jeda/Lanjut, banner layar 14 |
| Durasi audio | `TimeInterval`, jeda tidak dihitung | Timer `01:12:48` |
| Nomor segmen | `Int`, mulai dari 1 | "Segmen 5" |
| Level audio | `[Double]` 0...1, terbaru di akhir, ±5 per detik | Waveform |
| Penanda momen | `[TimeInterval]` dalam waktu audio | Chip "Momen ditandai" |
| Sisa ruang | jam rekaman (`Int?`), byte (`Int64?`), flag hampir penuh | Teks bawah layar, banner layar 15 ("tinggal 1,2 GB · cukup ± 9 jam") |

Aksi yang dipanggil UI: mulai (dengan judul, agenda, istilah), tandai, jeda, lanjut, simpan (konteks final + proses sekarang atau tidak).

**Perilaku Stop:** tombol Stop di UI hanya menjeda lalu membuka sheet 03. Rekaman baru ditutup saat user menekan Simpan. Batal di sheet kembali ke layar rekam dalam keadaan dijeda, jadi rekaman tidak boleh dibuang di titik ini.

**`Meeting` dan `MeetingProcessor` → Riwayat 04, Memproses 05, Proses gagal 13:**
- Langkah proses saat ini (PLAN-logic L1.2) dan perkiraan progres 0...1, untuk bar di kartu dan ring di layar 05. Urutan langkah di UI: rekaman tersimpan → segmen terunggah → transkripsi & pemisahan speaker → penyamaan label speaker → ringkasan, action items & MoM.
- Jenis dan pesan error terakhir (L1.2). Jenis "API key tidak valid" menonjolkan tombol "Cek API key" di layar 13.
- `process(_:)` dan `retry(_:)` (L6.3), untuk tombol "Simpan & proses" dan "Coba lagi".
- Agenda dan istilah khusus di `Meeting` (L1.1). UI mengisinya dari `MeetingContextDraft` (`title`, `agenda`, `terms`).
- Pemutar audio untuk tombol putar di sheet 03. Belum ada di PLAN-logic.
- Status per segmen untuk grid layar 13 (selesai, gagal, menunggu). Saat ini UI memakai `Segment.transcribed` dan menganggap segmen pertama yang belum selesai sebagai tempat gagal. Kalau D2 = A (gabung jadi satu file sebelum upload), grid ini perlu diganti; kabari sesi UI.
- Ukuran file per segmen dan jumlah segmen yang sudah terunggah, untuk keterangan langkah di layar 05 ("8 segmen · 412 MB di iPhone", "8/8 ke layanan STT").
- Desain layar 05 menulis "App boleh ditutup. Proses tetap jalan dan kamu dapat notifikasi saat MoM siap." UI belum memakai kalimat itu sampai D9 (proses di background) dan notifikasi diputuskan.

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
| `Views/`, `DesignSystem/` | Berjalan (sesi UI, branch `feat/ui-design-system`). Selesai dengan data sementara: DesignSystem, Beranda 01, Merekam 02/14/15, Simpan 03, Riwayat 04/12, Memproses 05, Proses gagal 13 |

Update tabel ini manual tiap ada item selesai — bukan otomatis.

## 5. Referensi
- `PRD_MoMentum.md` — requirement produk
- `docs/architecture.md` — keputusan arsitektur (vendor STT, storage, dll)
- `docs/design-handoff.md` — spec desain, token, daftar layar, node Figma
