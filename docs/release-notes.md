---
artifact: release-notes
version: "1.0"
created: 2026-11-25
status: draft
---

# MoMentum v0.1 (build pengembangan)

**Tanggal rilis:** 25 November 2026
**Commit:** `80c9b89` di `main`
**Dikerjakan oleh:** sesi UI (Claude Code) dan sesi Logic (Cline)

> **Status penting:** semua layar dan semua layanan di belakangnya sudah jadi, tapi **belum disambungkan satu sama lain**. Di build ini layar rekam masih memakai simulasi, jadi app belum benar-benar merekam dan memproses meeting. Penyambungan adalah pekerjaan berikutnya (lihat Known Issues).

## Highlights

### Semua layar MoMentum sudah bisa dicoba

Dari onboarding sampai MoM: beranda, layar rekam, simpan rekaman, riwayat, layar proses, detail meeting dengan ringkasan, action items, transkrip, dan MoM, serta pengaturan. Tampilannya mengikuti desain Figma dengan gaya Liquid Glass iOS 26.

### Mesin pemrosesan meeting sudah lengkap

Rekaman disimpan per 15 menit supaya tidak hilang kalau app tertutup, lalu digabung jadi satu file sebelum dikirim ke AssemblyAI. Dengan begitu nama speaker konsisten dari awal sampai akhir meeting. Transkrip kemudian diringkas oleh LLM pilihanmu menjadi ringkasan, action items lengkap dengan PIC, topik, dan keputusan.

### MoM siap dibagikan dalam beberapa format

Salin MoM sebagai teks, bagikan lewat WhatsApp atau email, atau simpan sebagai file PDF dan Markdown ke Files.

---

## New Features

### Merekam
- **Rekam satu ketuk:** tekan tombol rekam di Beranda. Judul, agenda, dan istilah khusus bisa diisi sebelum atau sesudah merekam.
- **Tandai momen penting:** ketuk Tandai saat merekam; momen itu ikut jadi konteks saat ringkasan dibuat.
- **Rekaman tahan gangguan:** rekaman berhenti sementara saat ada telepon masuk lalu lanjut otomatis, dan meeting yang terputus karena app ditutup paksa dipulihkan saat app dibuka lagi.
- **Peringatan ruang penyimpanan:** muncul banner kalau sisa ruang tinggal kurang dari sekitar 1 jam rekaman.

### Memproses
- **Transkrip per speaker dalam Bahasa Indonesia** lewat AssemblyAI, dengan istilah khusus sebagai petunjuk supaya tidak salah tulis.
- **Ringkasan, action items, topik, dan keputusan** dari LLM. Kalau PIC tidak jelas, ditulis "PIC belum jelas", bukan ditebak.
- **LLM bebas pilih:** layanan apa pun yang kompatibel dengan format OpenAI (OpenAI, OpenRouter, Ollama, dan sejenisnya), memakai key milikmu sendiri.
- **Antrean offline dan coba lagi:** tanpa internet, meeting masuk antrean dan diproses begitu online. Coba lagi melanjutkan dari langkah yang gagal tanpa upload ulang.
- **Proses di background dan notifikasi "MoM siap":** app boleh ditutup setelah menyimpan rekaman. Waktu selesainya bergantung pada iOS.
- **Generate ulang ringkasan** dari transkrip yang sudah ada, tanpa transkripsi ulang.

### Melihat dan membagikan
- **Riwayat meeting** dengan pencarian judul, filter status, dan kelompok waktu (hari ini, 7 hari terakhir, bulan ini).
- **Detail meeting** dalam empat tab: Ringkasan, Action items, Transkrip, MoM.
- **Ganti nama speaker** dari tab Transkrip; speaker yang belum bernama ditandai garis putus-putus.
- **Ekspor MoM** sebagai teks, Markdown, atau PDF lewat share sheet iOS.

### Pengaturan dan privasi
- **API key milik sendiri (BYOK):** disimpan di iOS Keychain, tidak pernah ditanam di kode.
- **Lama simpan audio** setelah MoM jadi (bawaan 30 hari); transkrip di server AssemblyAI dihapus setelah tersimpan di iPhone.
- **Pengingat profil instalasi:** Pengaturan menampilkan berapa hari lagi app perlu di-build ulang dari Xcode.
- **Nama di Beranda** untuk sapaan dan inisial avatar.

## Improvements

- **iOS minimum diturunkan ke 26.0** supaya bisa dipasang di iPhone yang lebih lama.
- **API key lebih aman:** tetap terbaca saat proses berjalan dengan layar terkunci, dan penyimpanan yang gagal kini dilaporkan, bukan diam-diam diabaikan.
- **Aksesibilitas:** label VoiceOver untuk timer, status proses, kartu meeting, dan kolom isian.

## Bug Fixes

Belum ada; ini rilis pertama.

## Known Issues

- **Layar belum tersambung ke layanan.** Layar rekam masih simulasi (tidak memakai mikrofon), dan tombol "Simpan & proses", "Coba lagi", "Proses sekarang", serta "Generate ulang" belum memanggil pemroses. Ini pekerjaan berikutnya.
- **Pengaturan LLM belum lengkap di layar.** Kolom Base URL dan nama model belum ada, jadi ringkasan belum bisa dijalankan dari app.
- **Nama speaker belum tersimpan** saat menekan "Simpan nama" (menunggu penyambungan).
- **DOCX (Word) belum didukung.** Butuh library tambahan; ekspor sementara ke PDF atau Markdown.
- **Transkrip yang sangat panjang** belum dipecah sebelum diringkas, jadi bisa melebihi batas model LLM.
- **Belum diuji di iPhone asli:** rekam 3 jam dengan layar terkunci, telepon masuk, dan kualitas pemisahan speaker untuk meeting di atas 2 jam.
- **Validitas API key belum dicek;** layar hanya menunjukkan key sudah terisi.
- Tombol lonceng (Beranda), kalender (Riwayat), dan Edit MoM tampil sesuai desain tapi belum punya fungsi.

---

## Coming Soon

Menyambungkan semua layar ke layanan supaya rekaman nyata bisa langsung diproses jadi MoM, lalu uji coba di iPhone dengan meeting sungguhan.

---

## Feedback

Catat temuan saat mencoba di iPhone, lalu bawa ke sesi berikutnya. Detail teknis untuk pengembang ada di `docs/update-2026-11-24.md`, `docs/handover.md`, dan `docs/PLAN-logic.md`.
