# MoMentum · Design Handoff untuk Vibe Coding (iOS 26, SwiftUI)

Versi 24 Nov 2026. Dokumen ini menjadi jembatan antara file Figma dan Claude Code. Lokasinya `docs/design-handoff.md`, berdampingan dengan `docs/architecture.md`.

- Figma: [MoMentum Assistance](https://www.figma.com/design/bsWJpX68qR4SKYnZsc7F66/MoMentum-Assistance)
- File key: `bsWJpX68qR4SKYnZsc7F66`, page `Page 1`
- PRD: `PRD_MoMentum.md` di root repo

## 1. Keputusan platform

| Hal | Keputusan |
| --- | --- |
| Target minimum | iOS 26, iPhone saja, portrait. Catatan: project Xcode saat ini masih `IPHONEOS_DEPLOYMENT_TARGET = 27.2`, turunkan ke 26.0 jika iOS 26 tetap jadi target |
| UI framework | SwiftUI, `NavigationStack` + `TabView` |
| Efek glass | Liquid Glass bawaan: `.glassEffect(.regular, in: .rect(cornerRadius:))`. Jangan meniru blur Figma secara manual |
| Font | Font sistem (SF Pro) lewat `Font.system(...)`. Dynamic Type aktif |
| Ikon | SF Symbols (pemetaan di bagian 6). Ikon custom di Figma hanya acuan bentuk |
| Ukuran frame Figma | 402 × 874 pt (iPhone 16 Pro). Layout wajib fleksibel, jangan hardcode lebar 402 |

## 2. Cara Claude Code membaca desain

1. Sambungkan Figma MCP. `.mcp.json` proyek ini masih kosong, jadi tambahkan dulu, misalnya `claude mcp add --transport http figma https://mcp.figma.com/mcp` (cek ulang perintahnya di dokumentasi Figma), lalu login dan pastikan muncul di `/mcp`.
2. Untuk tiap layar, panggil `get_design_context` dengan file key di atas dan node ID dari tabel bagian 8. Kalau plugin Figma terpasang, muat skill `figma-swiftui` dulu.
3. Hasil `get_design_context` berupa kode acuan (biasanya React/Tailwind). Terjemahkan ke SwiftUI memakai token dan komponen di dokumen ini, sedangkan nilai mentahnya cukup dijadikan acuan.
4. Pakai `get_screenshot` untuk membandingkan hasil build dengan desain.

## 3. Token warna

Sumber: variable collection `MoMentum / Color` di Figma. Simpan sebagai `MoMentum/MoMentum/DesignSystem/Colors.swift`. Project memakai folder tersinkron, jadi file baru di folder itu otomatis masuk target.

```swift
import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

enum MColor {
    // Brand (hijau evergreen)
    static let brand900 = Color(hex: 0x163A30)
    static let brand700 = Color(hex: 0x2C5E4F) // warna utama: tombol rekam, tab aktif
    static let brand500 = Color(hex: 0x4F8574)
    static let brand300 = Color(hex: 0x9FC2B5)
    static let brand100 = Color(hex: 0xDCEAE4)
    static let brand50  = Color(hex: 0xEEF4F1)
    // Neutral
    static let n0   = Color(hex: 0xFFFFFF)
    static let n50  = Color(hex: 0xF5F7F6)
    static let n100 = Color(hex: 0xEBEFED)
    static let n200 = Color(hex: 0xDCE2DF)
    static let n400 = Color(hex: 0xA3ADA8)
    static let n600 = Color(hex: 0x66716C) // teks sekunder
    static let n900 = Color(hex: 0x101714) // teks utama, tombol primer
    // Aksen dan status
    static let record    = Color(hex: 0xF25C2A) // titik merah saat merekam
    static let info      = Color(hex: 0x3E73D6), infoBg    = Color(hex: 0xE5EDFB)
    static let warn      = Color(hex: 0xC98314), warnBg    = Color(hex: 0xFBF0DC)
    static let danger    = Color(hex: 0xD24343), dangerBg  = Color(hex: 0xFBE6E6)
    static let success   = Color(hex: 0x2E8A5C), successBg = Color(hex: 0xDFF2E8)
    static let neutralBg = Color(hex: 0xEBEFED)
}
```

### Gradien latar

Dua gradien vertikal (atas ke bawah) dipakai sebagai latar layar.

```swift
enum MBackground {
    /// Layar rekam, beranda, onboarding
    static let deep = LinearGradient(stops: [
        .init(color: Color(hex: 0xFFFFFF), location: 0.0),
        .init(color: Color(hex: 0xF1F6F3), location: 0.4),
        .init(color: Color(hex: 0xA9C8BC), location: 0.7),
        .init(color: Color(hex: 0x2C5E4F), location: 1.0)
    ], startPoint: .top, endPoint: .bottom)

    /// Layar berisi banyak konten: riwayat, detail, pengaturan
    static let light = LinearGradient(stops: [
        .init(color: Color(hex: 0xFFFFFF), location: 0.0),
        .init(color: Color(hex: 0xF1F6F3), location: 0.5),
        .init(color: Color(hex: 0xCFE2D9), location: 1.0)
    ], startPoint: .top, endPoint: .bottom)
}
```

Pada latar `deep`, teks dan kontrol di sepertiga bawah layar memakai warna putih (lihat tombol Tandai, Jeda, Stop di layar 02).

## 4. Spacing, radius, dan tipografi

| Token | Nilai (pt) | Dipakai untuk |
| --- | --- | --- |
| `space.4 / 8 / 12 / 16 / 20 / 24 / 32` | 4, 8, 12, 16, 20, 24, 32 | Padding layar 20, jarak antarkartu 12 sampai 14 |
| `radius.sm` | 10 | Sel kecil (grid segmen) |
| `radius.md` | 16 | Input, banner info |
| `radius.lg` | 22 sampai 24 | Kartu glass |
| `radius.xl` | 36 | Bottom sheet |
| `radius.full` | Capsule | Tombol, chip, badge, tab bar |

Tipografi memakai text style bawaan supaya Dynamic Type berjalan. Ukuran Figma adalah acuan pada ukuran teks default.

| Peran | Ukuran Figma | SwiftUI |
| --- | --- | --- |
| Timer rekaman | 76 Semibold | `.system(size: 76, weight: .semibold).monospacedDigit()` |
| Judul layar (Riwayat, Pengaturan) | 34 Bold | `.largeTitle.bold()` |
| Judul meeting | 28 sampai 36 Semibold | `.title.weight(.semibold)` |
| Judul sheet | 22 Semibold | `.title2.weight(.semibold)` |
| Judul seksi (Action items) | 20 Semibold | `.title3.weight(.semibold)` |
| Isi | 14 sampai 15 Regular | `.subheadline` atau `.body` |
| Label kartu, tombol | 14 sampai 16 Semibold | `.subheadline.weight(.semibold)` |
| Meta, keterangan | 12 sampai 13 Regular | `.caption` / `.footnote` |
| Label seksi kapital (HARI INI) | 12 Semibold, tracking lebar | `.caption.weight(.semibold).tracking(1.2)` |

## 5. Komponen

Komponen lokal ada di frame `🧩 MoMentum Components` (node `5:2`).

| Komponen Figma | Node | SwiftUI | Catatan |
| --- | --- | --- | --- |
| Status Badge (5 varian) | `5:144` | `StatusBadge(status:)` | Capsule, titik 6 pt + label. Warna dari enum di bagian 7 |
| Tab Bar (3 varian) | `5:196` | `TabView` bawaan iOS 26 | Pakai tab bar native (sudah Liquid Glass). Desain custom hanya acuan isi: Beranda, Riwayat, Pengaturan |
| Meeting Card | `14:114` | `MeetingCard(meeting:)` | Properti: Title, Meta, Note, Progress label, plus toggle Show note, Show retry, Show progress |
| Segmented Tabs (4 varian) | `14:177` | `Picker(...).pickerStyle(.segmented)` | Isi: Ringkasan, Action items, Transkrip, MoM |
| IconButton glass (44 pt) | di tiap layar | `GlassIconButton(systemName:)` | Lingkaran 44 pt dengan `.glassEffect(in: .circle)` |
| Tombol primer / sekunder | di tiap layar | `.buttonStyle(.borderedProminent)` dengan tint `n900`, atau style custom capsule | Primer hitam `n900`, sekunder `n100`. Tinggi sekitar 52 pt |
| Waveform | layar 01, 02, 03 | `WaveformView(levels:)` | Bar vertikal dari level audio (`AVAudioRecorder.averagePower`). Bar yang sudah lewat opasitas 100%, sisanya 40% |
| Progress Ring | layar 05 | `ProgressRing(progress:)` | `Circle().trim(from:0,to:p)` dengan stroke 10 pt, `brand700` di atas `brand100` |
| Speaker Chip | layar 07 | `SpeakerChip(speaker:)` | Speaker tanpa nama memakai garis putus-putus `warn` |
| Action Item Row | layar 06 | `ActionItemRow(item:)` | PIC kosong menampilkan chip "PIC belum jelas" warna `warn` |
| Banner | layar 14, 15 | `StatusBanner(kind:)` | Kartu putih, ikon dalam lingkaran berwarna, judul + keterangan |

## 6. Pemetaan ikon ke SF Symbols

| Ikon Figma | SF Symbol | Ikon Figma | SF Symbol |
| --- | --- | --- | --- |
| `Icon/mic` | `mic.fill` | `Icon/search` | `magnifyingglass` |
| `Icon/home` | `house` | `Icon/key` | `key` |
| `Icon/history` | `clock.arrow.circlepath` | `Icon/check` | `checkmark` |
| `Icon/settings` | `gearshape` | `Icon/refresh` | `arrow.clockwise` |
| `Icon/sparkle` | `sparkles` | `Icon/cloud` | `cloud` |
| `Icon/bell` | `bell` | `Icon/lock` | `lock` |
| `Icon/back` | `chevron.left` | `Icon/file` | `doc.text` |
| `Icon/chevron` | `chevron.right` | `Icon/users` | `person.2` |
| `Icon/down` | `chevron.down` | `Icon/clock` | `clock` |
| `Icon/close` | `xmark` | `Icon/wave` | `waveform` |
| `Icon/play` | `play.fill` | `Icon/more` | `ellipsis` |
| `Icon/pause` | `pause.fill` | `Icon/calendar` | `calendar` |
| `Icon/stop` | `stop.fill` | `Icon/alert` | `exclamationmark.triangle` |
| `Icon/flag` | `flag` | `Icon/plus` | `plus` |
| `Icon/share` | `square.and.arrow.up` | `Icon/tag` | `tag` |
| `Icon/copy` | `doc.on.doc` | `Icon/edit` | `pencil` |

Logo wordmark memakai `waveform` berwarna `brand700` dan teks "MoMentum" dengan "MoM" berwarna `brand700`.

## 7. Model status meeting

Enum `MeetingStatus` sudah ada di `Models/Meeting.swift` dengan lima case yang sama dengan desain. Jangan membuat enum baru. Tambahkan label dan warna lewat extension di `DesignSystem/MeetingStatus+Style.swift`:

```swift
import SwiftUI

extension MeetingStatus {
    var label: String {
        switch self {
        case .recorded: "Direkam"
        case .queued: "Menunggu"
        case .processing: "Diproses"
        case .done: "Selesai"
        case .failed: "Gagal"
        }
    }
    var colors: (fg: Color, bg: Color) {
        switch self {
        case .recorded: (MColor.n600, MColor.neutralBg)
        case .queued: (MColor.warn, MColor.warnBg)
        case .processing: (MColor.info, MColor.infoBg)
        case .done: (MColor.success, MColor.successBg)
        case .failed: (MColor.danger, MColor.dangerBg)
        }
    }
}
```

Langkah proses di layar 05 berurutan: rekaman tersimpan, segmen terunggah, transkripsi dan pemisahan speaker, penyamaan label speaker antarsegmen, lalu ringkasan, action items, dan MoM.

## 8. Daftar layar

Link per layar: `https://www.figma.com/design/bsWJpX68qR4SKYnZsc7F66/MoMentum-Assistance?node-id=<node dengan tanda hubung>`, misalnya `node-id=13-29`.

| # | Layar | Node | View SwiftUI | Requirement PRD |
| --- | --- | --- | --- | --- |
| 01 | Beranda | `13:29` | `HomeView` | Rekam audio di app, Konteks meeting |
| 02 | Merekam | `13:157` | `RecordingView` | Rekam audio, Rekaman tahan gangguan, Penanda momen penting |
| 03 | Simpan rekaman (sheet) | `13:286` | `SaveRecordingSheet` | Konteks meeting (judul, agenda, istilah), Antrean offline |
| 04 | Riwayat | `14:178` | `HistoryView` | Riwayat meeting, Antrean offline (status per meeting) |
| 05 | Memproses | `14:374` | `ProcessingView` | Transkrip dengan label speaker (proses cloud) |
| 06 | Detail · Ringkasan | `14:445` | `MeetingDetailView` (tab Ringkasan) | Ringkasan singkat, Action items dan PIC, Generate ulang |
| 07 | Transkrip + ganti nama speaker | `16:297` | `TranscriptTab` + `RenameSpeakerSheet` | Transkrip per speaker, Ganti nama speaker, Generate ulang |
| 08 | MoM & bagikan | `16:440` | `MoMTab` | MoM terstruktur, Export dan share, Edit MoM |
| 09 | Pengaturan | `16:543` | `SettingsView` | API key BYOK (Keychain), batas biaya |
| 10 | Onboarding · API key | `18:396` | `OnboardingKeyView` | API key di Settings (BYOK) |
| 11 | Onboarding · izin mikrofon | `18:471` | `OnboardingMicView` | Rekam audio, persona peserta yang direkam |
| 12 | Riwayat kosong | `18:539` | `HistoryView` (state kosong) | Riwayat meeting |
| 13 | Proses gagal | `18:598` | `ProcessingView` (state gagal) | Antrean proses, status gagal dan coba lagi |
| 14 | Merekam · dijeda telepon | `18:682` | `RecordingView` (state dijeda) | Rekaman tahan gangguan |
| 15 | Merekam · ruang hampir penuh | `18:817` | `RecordingView` (banner peringatan) | Peringatan ruang penyimpanan |

Layar 06, 07, dan 08 adalah satu `MeetingDetailView` dengan segmented control. Tab "Action items" belum punya layar tersendiri; isinya sama dengan bagian Action items di layar 06 dalam bentuk daftar penuh.

## 9. Alur navigasi

```
Peluncuran pertama (belum ada API key)
  └─ 10 Onboarding API key → 11 Izin mikrofon → TabView

TabView
  ├─ Beranda (01)
  │    └─ tombol rekam → 02 Merekam (fullScreenCover)
  │         ├─ state 14 (telepon masuk) dan 15 (ruang hampir penuh)
  │         └─ Stop → 03 Simpan rekaman (.sheet, detent .large)
  │              └─ Simpan & proses → 05 Memproses → 06 Detail
  ├─ Riwayat (04, kosong = 12)
  │    ├─ kartu Selesai → 06 Detail (push)
  │    ├─ kartu Diproses atau Menunggu → 05 Memproses
  │    └─ kartu Gagal → 13 Proses gagal → Coba lagi atau Cek API key (ke 09)
  └─ Pengaturan (09)

06 Detail: Ringkasan | Action items | Transkrip (07) | MoM (08)
  ├─ ketuk chip speaker → RenameSpeakerSheet (.sheet, detent .medium)
  └─ Bagikan → ShareLink (teks atau Markdown)
```

## 10. Batasan file desain saat ini

- **Isi layar adalah contoh.** Nama vendor (AssemblyAI, Anthropic), biaya, durasi, dan isi meeting belum final, karena di PRD vendor STT dan batas biaya masih berstatus open.
- **Warna semi-transparan tidak terikat variable.** Di Figma, opasitas hilang kalau warnanya diikat ke variable, jadi lapisan glass dan scrim memakai warna token dengan opasitas tertulis langsung. Di SwiftUI, lapisan itu diganti `.glassEffect` dan `Color.black.opacity(0.3)`, sehingga tidak perlu token sendiri.
- **Belum ada mode gelap.** Mulai dengan `.preferredColorScheme(.light)` sampai desain dark tersedia.
- **Belum ada layar untuk requirement S dan C berikut:** edit transkrip inline, transkrip kasar on-device saat merekam, pencarian lintas meeting, dan tanya jawab ke isi meeting. Requirement W (rekam meeting online) memang di luar rilis ini.
- **Tab bar custom di Figma berbeda dari tab bar native iOS 26.** Bagian 5 menyarankan versi native supaya kode lebih sedikit. Kalau tetap mau versi custom, buat `TabView` dengan tab bar disembunyikan, lalu overlay komponen sendiri.

## 11. Prompt awal untuk Claude Code

```
Baca docs/design-handoff.md dan PRD. Buat DesignSystem (Colors.swift,
Backgrounds.swift, komponen di bagian 5) lebih dulu, lalu bangun layar 01, 02,
dan 03 memakai get_design_context dari Figma MCP dengan node ID di bagian 8.
Target iOS 26, SwiftUI, Liquid Glass, font sistem, ikon SF Symbols sesuai
bagian 6. Setelah tiap layar, ambil get_screenshot node yang sama dan
bandingkan dengan Preview SwiftUI sebelum lanjut.
```
