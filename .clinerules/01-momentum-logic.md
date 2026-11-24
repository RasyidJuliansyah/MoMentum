# MoMentum · aturan untuk Cline (sesi Logic)

Kamu mengerjakan bagian **Logic** (Models + Services) app iOS MoMentum. Bagian UI dikerjakan paralel oleh sesi lain (Claude Code) di folder terpisah.

## Wajib dibaca sebelum tugas pertama di setiap task

1. `CLAUDE.md`: aturan project, perintah, dan konvensi. Berlaku penuh untukmu walaupun namanya CLAUDE.md.
2. `docs/PLAN-logic.md`: rencana kerja, urutan tugas, dan keputusan D1 sampai D9. Kerjakan tugas sesuai urutan, satu per giliran.
3. `docs/handover.md`: pembagian wilayah file dan kontrak nama.
4. `docs/architecture.md` dan `PRD_MoMentum.md`, sesuai kebutuhan tugas.

## Wilayah file

Boleh diubah:
- `MoMentum/MoMentum/Models/`
- `MoMentum/MoMentum/Services/`
- `MoMentum/MoMentumTests/`
- Baris `.environment(...)` dan schema di `MoMentum/MoMentum/MoMentumApp.swift`
- `docs/handover.md` bagian 3 dan 4, `docs/PLAN-logic.md` (centang tugas dan catatan)

Tidak boleh diubah: `Views/`, `DesignSystem/`, `ContentView.swift`, file `docs/` lain, dan pengaturan project Xcode tanpa persetujuan.

## Perintah tes

```bash
xcodebuild test -project MoMentum/MoMentum.xcodeproj -scheme MoMentum \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:MoMentumTests
```

## Cara kerja

- Tugas rumit atau yang ditandai "Plan mode" di rencana: paparkan 2 sampai 3 pendekatan beserta trade-off-nya, lalu tunggu pilihan sebelum menulis kode.
- Fitur baru datang bersama tesnya. Bug: tulis tes yang gagal dulu.
- Commit setelah tiap tugas lolos tes, format `feat(scope): deskripsi`. Untuk mundur, pakai git, bukan checkpoint.
- Keputusan yang berstatus "belum diputuskan": tanyakan, jangan menebak.

## Jangan lakukan

- Mendefinisikan ulang atau mengganti nama di kontrak `docs/handover.md` bagian 3, atau menambah case `MeetingStatus`, tanpa koordinasi.
- Menambah dependency (Swift Package) tanpa alasan dan persetujuan. Cukup pakai `URLSession`, AVFoundation, dan Network.
- Menulis API key di kode, tes, atau fixture. Tes memakai nilai palsu seperti `"test-key"`.
- Me-log API key atau isi transkrip.
- Commit rekaman meeting atau transkrip nyata. Fixture harus sintetis.
- Push ke `main` tanpa review.
- Mengubah schema SwiftData secara tidak kompatibel setelah ada data nyata, tanpa migration plan.
