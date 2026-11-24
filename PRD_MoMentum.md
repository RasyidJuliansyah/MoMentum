PRD_MoMentum
Nov 24, 2026 · @RJ
App iOS untuk merekam meeting tatap muka, lalu menghasilkan transkrip per speaker, ringkasan, action items, dan MoM dalam Bahasa Indonesia. Versi pertama dipakai sendiri, tapi arsitekturnya disiapkan supaya bisa dibuka ke publik nanti.
Item
Isi
Target Release
[TBD]
Epic
Meeting Summary iOS v1 (pribadi)
Document Status
Draft
Created Date
24 Nov 2026
Updated Date
24 Nov 2026
Product Manager
[TBD] (pemilik dokumen)
Engineering
Vibe coding dengan Claude Code
Designer
[TBD]
QA
[TBD]
Benchmark
[TBD] (kandidat untuk dibandingkan: Otter, Fireflies, Plaud; link belum dicek)
Background
Meeting tatap muka di kantor sering berjalan lebih dari 2 jam. Kalau mencatat sambil ikut berdiskusi, salah satunya pasti kalah: catatan jadi bolong, atau kita jadi pasif di meeting. Menyusun MoM dari catatan dan ingatan setelah meeting juga makan waktu, tapi angkanya belum pernah diukur [perlu diukur].
App ini dibuat untuk dipakai sendiri dulu. Kode dan arsitekturnya tetap disiapkan supaya bisa dibuka ke publik tanpa harus ditulis ulang. Pembanding dengan app sejenis yang sudah ada belum dilakukan dan masuk ke Customer Research.
Ada tiga batasan yang ikut membentuk scope versi pertama:
• Distribusi tanpa akun berbayar. Dengan Apple Account gratis (Personal Team di Xcode), profil instalasi kedaluwarsa 7 hari setelah dibuat, jadi app harus di-build ulang dari Xcode tiap minggu. Batasnya juga 3 app per perangkat (Apple Developer). Anggota Apple Developer Program berbayar mendapat profil yang berlaku sampai sekitar satu tahun dan akses TestFlight. Harga keanggotaan perlu dicek ulang sebelum memutuskan.
• Meeting online belum bisa direkam dengan mudah di iOS. Karena itu fitur ini ditunda ke fase 2.
• Dukungan Bahasa Indonesia on-device belum pasti. Model transkripsi baru di iOS 26 (SpeechTranscriber) dilaporkan baru mencakup sekitar sepuluh bahasa, sedangkan DictationTranscriber mencakup lebih banyak (laporan developer di DEV Community). Apakah Bahasa Indonesia termasuk, perlu dicek langsung di perangkat lewat supportedLocales.
Objectives

1.  Bisa ikut diskusi penuh selama meeting tanpa mencatat manual.
2.  Mempercepat waktu dari meeting selesai sampai MoM siap dibagikan.
3.  Tidak ada rekaman yang hilang, termasuk meeting yang berjalan lebih dari 2 jam.
4.  Menjaga biaya API tetap kecil untuk pemakaian pribadi, dengan batas bulanan yang ditentukan sendiri [TBD].
    Definition
    Istilah
    Arti di dokumen ini
    Diarization
    Pemisahan transkrip berdasarkan siapa yang bicara. Hasilnya berupa label Speaker 1, Speaker 2, dan seterusnya, yang namanya diisi user.
    Hybrid processing
    Rekaman dan penyimpanan dilakukan di HP. Transkrip akhir, diarization, dan ringkasan diproses di cloud. Transkrip kasar on-device bersifat opsional dan bergantung hasil spike.
    Segmen rekaman
    Potongan file audio dengan durasi tetap (usulan awal 10 sampai 15 menit, masih asumsi) supaya crash tidak menghapus seluruh rekaman dan file tetap muat dalam batas upload API.
    MoM
    Minutes of Meeting: info meeting, peserta, topik, keputusan, dan action items.
    Action item
    Tugas yang disepakati di meeting, lengkap dengan PIC dan tenggat bila disebut.
    PIC
    Person in charge, yaitu orang yang bertanggung jawab atas satu action item.
    BYOK
    Bring your own key. User memasukkan API key miliknya sendiri di halaman Settings.
    Provider adapter
    Lapisan kode yang membungkus layanan STT dan LLM, supaya vendor bisa diganti atau dipindah ke backend tanpa mengubah UI.
    Success Metrics
    Proyek ini tidak terhubung ke key result perusahaan, jadi kolom pertama diisi tujuan pribadi dari bagian Objectives. Semua baseline belum diukur, dan target ditetapkan setelah spike.
    Company Key Results
    Metrics
    Tidak ada rekaman hilang (Objective 3)
    Persentase rekaman di atas 2 jam yang tersimpan utuh. Target 100% dari 5 meeting uji pertama.
    MoM lebih cepat siap (Objective 2)
    Menit dari tombol stop sampai MoM tampil. Baseline manual: [perlu diukur]. Target: [TBD setelah spike].
    Transkrip bisa dipercaya (Objective 1)
    Jumlah koreksi manual per 10 menit transkrip, diukur pada 3 rekaman nyata. Target: [TBD setelah spike].
    Ringkasan bisa langsung dipakai (Objective 1)
    Persentase MoM yang dibagikan tanpa diedit besar. Target: [TBD].
    Biaya terkendali (Objective 4)
    Biaya API per jam audio dan total per bulan. Target: di bawah batas bulanan [TBD].
    Guardrail
    Konsumsi baterai selama 2 jam merekam dengan layar terkunci, dan ruang penyimpanan per jam audio. Batas: [perlu diukur saat spike].
    Customer Research
    Belum ada riset. Dasar dokumen ini adalah kebutuhan pribadi pemilik proyek. Usulan validasi sebelum dan selama build:
    • Mencatat meeting sendiri selama 2 minggu: durasi, jumlah peserta, dan waktu yang dihabiskan untuk menyusun MoM. Data ini menjadi baseline Success Metrics.
    • Mencoba 2 sampai 3 app perekam meeting yang sudah ada dengan rekaman berbahasa Indonesia, lalu mencatat apa yang kurang.
    • Untuk fase publik, wawancara 5 rekan kantor tentang cara mereka mencatat meeting dan kesediaan mereka direkam.
    User Persona
    • Profesional kantor dengan banyak meeting tatap muka (persona utama, pemilik app). Sering memimpin atau ikut meeting panjang dan perlu membagikan MoM serta action items ke tim. Masalah utamanya: tidak bisa fokus berdiskusi sambil mencatat, dan menyusun MoM setelahnya memakan waktu.
    • Peserta meeting yang direkam (persona sekunder). Tidak memakai app, tapi suaranya diproses. Mereka perlu tahu bahwa meeting direkam. Persona ini menjadi penting saat app dibuka ke publik.
    Product Requirements
    Versi minimum yang bisa dipakai dibentuk oleh baris M: rekam, transkrip, ringkasan, action items, MoM, dan export.
    Requirements
    User Story
    Priority
    Notes
    Rekam audio di app
    Sebagai profesional kantor, saya ingin menekan satu tombol untuk merekam meeting, sehingga saya bisa langsung fokus berdiskusi.
    M
    Rekaman tetap jalan saat layar terkunci atau app di background (background audio mode). Diuji untuk durasi 3 jam.
    Rekaman tahan gangguan
    Sebagai profesional kantor, saya ingin rekaman tidak hilang meski ada telepon masuk atau app tertutup, sehingga meeting panjang tetap terekam utuh.
    M
    Simpan per segmen ke penyimpanan lokal. Telepon masuk membuat rekaman pause, lalu lanjut otomatis setelahnya. Tampilkan peringatan bila ruang penyimpanan hampir penuh.
    Transkrip Bahasa Indonesia dengan label speaker
    Sebagai profesional kantor, saya ingin transkrip yang memisahkan tiap pembicara, sehingga saya tahu siapa yang mengatakan apa.
    M
    Lewat cloud STT dengan diarization. Vendor dipilih saat spike. Audio di atas 2 jam dikirim per segmen, lalu label speaker antarsegmen perlu disamakan; risiko teknis ini dicek saat spike.
    Ganti nama speaker
    Sebagai profesional kantor, saya ingin mengubah label Speaker 1 menjadi nama orang, sehingga transkrip dan PIC terbaca jelas.
    M
    Ubah sekali, berlaku di seluruh transkrip dan MoM.
    Ringkasan singkat
    Sebagai profesional kantor, saya ingin ringkasan beberapa paragraf, sehingga saya bisa menangkap isi meeting dalam satu menit.
    M
    Dihasilkan LLM dari transkrip. Prompt memakai Bahasa Indonesia.
    Action items dan PIC
    Sebagai profesional kantor, saya ingin daftar tugas lengkap dengan PIC, sehingga tindak lanjut tidak terlewat.
    M
    PIC diambil dari nama speaker. Bila tidak jelas, tulis "PIC belum jelas" dan jangan menebak.
    MoM terstruktur
    Sebagai profesional kantor, saya ingin MoM berformat tetap, sehingga bisa langsung dibagikan ke tim.
    M
    Format: info meeting, peserta, topik, keputusan, action items. Template bisa diubah di fase berikutnya.
    API key di Settings (BYOK)
    Sebagai pemilik app, saya ingin memasukkan API key sendiri, sehingga tidak ada key yang tertanam di kode.
    M
    Disimpan di iOS Keychain. Semua panggilan STT dan LLM lewat provider adapter supaya nanti bisa dipindah ke backend.
    Riwayat meeting
    Sebagai profesional kantor, saya ingin melihat daftar meeting lama, sehingga saya bisa membuka MoM sebelumnya.
    M
    Disimpan lokal di HP. Tiap meeting menampilkan judul, tanggal, durasi, dan status proses.
    Export dan share
    Sebagai profesional kantor, saya ingin membagikan MoM, sehingga tim langsung menerimanya.
    M
    Lewat share sheet iOS (salin, WhatsApp, email). Format teks atau Markdown.
    Edit transkrip dan MoM
    Sebagai profesional kantor, saya ingin memperbaiki kata yang salah, sehingga MoM yang dibagikan akurat.
    S
    Edit manual di layar detail.
    Generate ulang ringkasan
    Sebagai profesional kantor, saya ingin membuat ulang ringkasan setelah nama speaker diganti, sehingga hasilnya ikut terbarui.
    S
    Memakai transkrip terbaru tanpa transkripsi ulang.
    Antrean proses saat offline
    Sebagai profesional kantor, saya ingin rekaman diproses otomatis begitu ada internet, sehingga saya tidak perlu mengulang.
    S
    Status per meeting: direkam, menunggu, diproses, selesai, gagal (dengan tombol coba lagi).
    Penanda momen penting
    Sebagai profesional kantor, saya ingin menandai momen saat merekam, sehingga bagian itu diprioritaskan di ringkasan.
    S
    Disimpan sebagai timestamp, lalu dikirim ke LLM sebagai konteks.
    Transkrip kasar on-device
    Sebagai profesional kantor, saya ingin melihat teks saat masih merekam, sehingga saya yakin rekaman berjalan.
    S
    Hanya bila spike membuktikan Bahasa Indonesia didukung on-device. Jika tidak, turun ke W.
    Konteks meeting
    Sebagai profesional kantor, saya ingin mengisi judul, agenda, dan istilah khusus, sehingga transkrip dan ringkasan lebih tepat.
    S
    Istilah dipakai sebagai keyword hint STT bila vendor mendukung.
    Pencarian lintas meeting
    Sebagai profesional kantor, saya ingin mencari kata di semua meeting, sehingga keputusan lama mudah ditemukan.
    C
    Pencarian teks lokal.
    Tanya jawab ke isi meeting
    Sebagai profesional kantor, saya ingin bertanya ke isi meeting, sehingga saya tidak perlu membaca ulang transkrip.
    C
    Chat berbasis transkrip satu meeting.
    Export ke Notion atau Google Docs
    Sebagai profesional kantor, saya ingin MoM masuk ke tool kerja tim, sehingga tidak perlu salin tempel.
    C
    Lewat API masing-masing.
    Rekam meeting online
    Sebagai profesional kantor, saya ingin merekam Zoom atau Meet, sehingga meeting online ikut tercatat.
    W
    Fase 2. Butuh riset pendekatan (bot, ReplayKit, atau integrasi).
    MoSCoW: M = Must Have, S = Should Have, C = Could Have, W = Will Not Have untuk rilis ini.
    Milestones / Roll Out Plan
    Tanggal belum ditetapkan. Setiap fase baru dimulai setelah gate di atasnya terpenuhi.
    Fase 1 adalah target utama dokumen ini. Fase 3 membutuhkan PRD terpisah karena menyangkut backend dan kepatuhan data.
    User Flow & Design
    Alur utama, dari rekam sampai MoM dibagikan:
5.  Buka app, lalu tekan Rekam. Judul meeting boleh diisi sekarang atau nanti.
6.  App merekam dan menyimpan audio per segmen di HP. Rekaman tetap jalan saat layar terkunci dan berhenti sementara saat ada telepon masuk.
7.  Tekan Stop. Meeting masuk ke riwayat dengan status "direkam".
8.  Jika ada internet, app mengirim segmen audio ke STT cloud. Jika tidak, meeting masuk antrean dan dikirim otomatis saat online.
9.  Transkrip dengan label Speaker 1, Speaker 2, dan seterusnya tampil. User mengganti label dengan nama orang. Langkah ini boleh dilewati, tapi PIC lalu memakai label Speaker.
10. App mengirim transkrip ke LLM untuk membuat ringkasan, action items dengan PIC, dan MoM.
11. User membaca, mengedit bila perlu, lalu membagikan MoM lewat share sheet.
    Hasil dari kedua vendor disimpan kembali ke penyimpanan lokal. Di Fase 3, provider adapter cukup diarahkan ke backend proxy, sehingga UI dan alur di atas tidak perlu diubah.
    Link desain Figma: MoMentum Assistance (9 layar iOS v1 dan board komponen).
    Questions & Answers
    Questions
    Answers
    Date Answered
    Untuk siapa app ini?
    Pribadi dulu, dengan arsitektur yang siap dibuka ke publik.
    24 Nov 2026
    Platform awal?
    iOS.
    24 Nov 2026
    Sumber audio?
    Rekam langsung untuk meeting tatap muka. Meeting online ditunda ke fase 2.
    24 Nov 2026
    Bahasa meeting?
    Bahasa Indonesia saja.
    24 Nov 2026
    Output yang dibutuhkan?
    Ringkasan singkat, action items dengan PIC, transkrip per speaker, dan MoM terstruktur.
    24 Nov 2026
    Audio diproses di mana?
    Hybrid.
    24 Nov 2026
    Model bisnis?
    Gratis, pemakaian pribadi, dengan API key milik sendiri.
    24 Nov 2026
    Target user awal?
    Profesional kantor.
    24 Nov 2026
    Durasi meeting yang biasa direkam?
    Lebih dari 2 jam.
    24 Nov 2026
    Akun Apple Developer?
    Belum punya. Mulai dengan Personal Team gratis.
    24 Nov 2026
    Vendor STT mana yang dipakai? Kandidat yang mengklaim mendukung Bahasa Indonesia dengan diarization: AssemblyAI, Soniox, Speechmatics. Klaim ini dari halaman vendor dan belum diuji.
    [open]

Bagaimana performa diarization untuk rekaman di atas 2 jam? Sebagian layanan membatasi durasi saat diarization aktif.
[open]

Apakah Bahasa Indonesia didukung on-device di iPhone yang dipakai?
[open]

Berapa batas biaya API per bulan?
[open]

Rekaman audio disimpan berapa lama setelah MoM jadi?
[open]

Kapan beralih ke Apple Developer Program berbayar? Usulan: setelah MVP terbukti dipakai rutin.
[open]

Apakah Mac dengan Xcode sudah tersedia untuk build?
[open]

Bagaimana memberi tahu peserta bahwa meeting direkam?
[open]

Out of Scope
• Rekaman meeting online (Zoom, Meet, Teams). Masuk fase 2.
• Versi Android.
• Bahasa selain Indonesia, termasuk deteksi campuran Indonesia dan Inggris secara khusus.
• Akun user, login, dan sinkronisasi antarperangkat.
• Backend milik sendiri. Pada versi pribadi, app memanggil API vendor langsung dengan key user.
• Pembayaran, langganan, dan rilis ke App Store.
• Kepatuhan UU PDP dan kebijakan privasi publik. Wajib dikerjakan sebelum fase publik.
Roll Out Approval
Selama fase pribadi cukup self-review. Checklist ini disiapkan untuk fase publik.
[ ] QA
[ ] Tech Lead
[ ] PMO Tech
[ ] Product Discovery Lead
[ ] CTO
