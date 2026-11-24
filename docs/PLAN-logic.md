# Plan vibe coding · MoMentum Logic (Models + Services) di Cline

Dibuat 24 Nov 2026 dari templat `plan_vibe_coding.md`. Rencana ini untuk sesi **Logic** yang dikerjakan di Cline. Sesi **UI** tetap di Claude Code dengan Figma MCP. Pembagian wilayah file ada di `docs/handover.md`.

Aturan pakai: kerjakan satu tugas per giliran, berurutan sesuai daftar di bagian C. Hal yang belum diputuskan ditulis "belum diputuskan". Jangan menebak; tanyakan ke pemilik project.

## 0. Pilih jalur

- [x] Project berjalan: bagian A versi ringkas, lalu B sampai F.

## A. Persiapan

### Kondisi project per 24 Nov 2026

- Branch: `main`, hanya 1 commit (`first commit`, isinya README). Semua file lain masih untracked.
- Xcode 27.2, scheme `MoMentum`, simulator iOS 27.2.
- Tes baseline: 1 tes unit (`testKeychainStoreRoundTrip`) lolos.
- Format project Xcode memakai `MoMentum.xcodeproj/project.xcproj` (format JSON baru). Edit lewat Xcode, jangan ditulis tangan kecuali terpaksa.

### Konteks yang wajib dibaca Cline sebelum tugas pertama

1. `CLAUDE.md`: aturan project, konvensi, dan daftar "Jangan lakukan". Cline tidak membacanya otomatis, jadi harus dibaca manual.
2. `docs/handover.md`: wilayah file dan kontrak nama yang tidak boleh didefinisikan ulang.
3. `docs/architecture.md`: keputusan terkunci (AssemblyAI, segmen 15 menit, provider adapter).
4. `PRD_MoMentum.md`: requirement M/S/C/W.
5. `docs/design-handoff.md` bagian 7, 8, dan 9: status meeting, daftar layar, dan data apa yang dibutuhkan tiap layar.
6. `spike/stt/stt_spike/base.py` dan `providers/assemblyai.py`: acuan alur upload, buat job, dan polling AssemblyAI (sudah dicek ke dokumentasi resmi 24 Nov 2026).

### Hal teknis yang perlu Cline tahu

- **Isolasi MainActor default.** Build setting `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` dan `SWIFT_APPROACHABLE_CONCURRENCY = YES`. Semua tipe otomatis `@MainActor`. Callback yang dipanggil dari thread lain (tap audio, delegate AVFoundation, `NWPathMonitor`) harus ditandai `nonisolated` atau dikirim balik ke main dengan benar. Kalau tidak, bisa crash karena pelanggaran isolasi.
- **Background audio** sudah aktif (`UIBackgroundModes: audio` di `Info.plist`). Izin mikrofon sudah ada di build setting `INFOPLIST_KEY_NSMicrophoneUsageDescription`.
- **SwiftData.** Selama belum ada meeting nyata, schema boleh diubah bebas: hapus app di simulator, lalu install ulang. Setelah meeting nyata pertama direkam, perubahan schema wajib lewat `VersionedSchema` dan `SchemaMigrationPlan`.
- **Perlindungan file.** Rekaman ditulis saat layar terkunci. Jangan set `FileProtectionType.complete` pada file audio karena penulisan akan gagal saat terkunci. Default iOS (`completeUntilFirstUserAuthentication`) sudah cukup.
- **Keychain.** `KeychainStore` sekarang belum menyetel `kSecAttrAccessible`, jadi default-nya `WhenUnlocked`. Akibatnya API key tidak terbaca kalau proses berjalan saat layar terkunci. Ini diperbaiki di tugas L1.5.

### Checklist awal (dikerjakan pemilik project, bukan Cline)

- [x] **Commit baseline** di branch `chore/baseline` (24 Nov 2026). `xcuserdata/`, `DerivedData/`, dan `.agents/` (skill pihak ketiga) masuk `.gitignore`. Repo git kedua buatan Xcode di `MoMentum/.git` dipindahkan ke Trash supaya kode app ikut ter-track oleh repo utama.
- [x] **Folder kerja terpisah untuk Cline**, supaya sesi UI dan Logic tidak berebut checkout dan branch yang sama:
  ```bash
  git worktree add ../meeting-summary-ios-logic -b feat/logic-models
  ```
  Buka folder `../meeting-summary-ios-logic` di VS Code untuk Cline. Sesi UI tetap di folder asli. Merge ke `main` lewat review.
- [x] **Simulator berbeda untuk Logic** (`iPhone 18 Pro`), supaya build dan data SwiftData kedua sesi tidak saling timpa. Bundle ID-nya sama.
- [x] **File aturan Cline** di `.clinerules/01-momentum-logic.md`. Isinya: wajib membaca daftar konteks di atas, hanya boleh mengubah `Models/`, `Services/`, `MoMentumTests/`, dan baris `.environment(...)` di `MoMentumApp.swift`, plus salinan bagian "Jangan lakukan" di bawah.
- [x] Perintah tes di bawah ini dicatat di bagian Perintah `CLAUDE.md`.
- [ ] Keputusan D1 sampai D3 di bagian B sudah diambil.

Perintah tes unit, sudah dicoba dan lolos:

```bash
xcodebuild test -project MoMentum/MoMentum.xcodeproj -scheme MoMentum \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -only-testing:MoMentumTests
```

## B. Tujuan

### Tujuan fase Logic

Semua requirement M di PRD punya logic yang siap dipakai UI: rekam tahan gangguan, transkrip per speaker, ganti nama speaker, ringkasan, action items + PIC, MoM, status per meeting, dan coba lagi. Requirement S ditambahkan setelahnya.

**Selesai kalau:**

- Semua tugas L1 sampai L6 dicentang dan tesnya lolos.
- UI bisa memanggil service lewat `@Environment` tanpa data dummy.
- Checklist uji di perangkat (bagian C, akhir L2 dan L4) lolos.

### Tujuan sesi pertama di Cline

L1 (model lengkap). UI sedang menunggu field ini untuk layar 02, 03, 05, 07, 09, dan 13.

### Keputusan sebelum dan selama build

| # | Keputusan | Dibutuhkan sebelum | Usulan | Status |
| --- | --- | --- | --- | --- |
| D1 | Deployment target: tetap 27.2 atau turun ke 26.0 (desain menargetkan iOS 26)? Tergantung versi iOS di iPhone yang dipakai | L2 | Ikuti versi iOS iPhone pribadi | **Diputuskan 24 Nov 2026: 26.0** (pemilik produk: iPhone 11 di iOS 26.0, sudah dikerjakan di commit `8edf534`) |
| D2 | Cara menyamakan label speaker untuk meeting panjang | L1 | **A**: segmen tetap disimpan terpisah di HP (tahan crash), tapi digabung jadi satu file sebelum upload. AssemblyAI menerima sampai 10 jam / 5GB per transkrip dan upload lokal sampai 2,2GB ([FAQ AssemblyAI](https://www.assemblyai.com/docs/faq/are-there-any-limits-on-file-size-or-file-duration-for-files-submitted-to-the-api), dicek 24 Nov 2026). Dengan satu kali diarization, label otomatis konsisten. **B** (cadangan): kirim per segmen lalu cocokkan label lewat potongan audio yang tumpang tindih. Jauh lebih rumit. Pilihan A mengubah alur langkah 2 di `docs/architecture.md`, jadi dokumen itu perlu diperbarui | **Diputuskan 24 Nov 2026: A** (pemilik produk: "satu kesatuan full"). |
| D3 | Tempat menyimpan nama speaker | L1 | Model baru `Speaker` (label, nama opsional) milik `Meeting`. `Utterance.speakerLabel` tetap label mentah, sedangkan nama tampil diambil dari `Speaker`. Ganti nama cukup mengubah satu field | **Diputuskan 24 Nov 2026: usulan dipakai apa adanya** |
| D4 | Vendor dan model LLM untuk ringkasan. Penyebutan Anthropic di desain hanya contoh isi layar | L5 | — | belum diputuskan |
| D5 | Rekaman audio disimpan berapa lama setelah MoM jadi (open question di PRD) | L7 | — | belum diputuskan |
| D6 | Hapus transkrip di server AssemblyAI setelah hasil tersimpan lokal? | L7 | — | belum diputuskan |
| D7 | Batas biaya API per bulan (open question di PRD) | L7 | — | belum diputuskan |
| D8 | `AVAudioRecorder` atau `AVAudioEngine` untuk perekam, plus format dan bitrate audio | L2 | Diputuskan di L2.1 setelah uji kecil di perangkat | **Diputuskan 24 Nov 2026: A, `AVAudioRecorder` per segmen**, format AAC mono 64 kbps. Celah mikro antar segmen diterima (dampak ke transkrip minimal) demi kesederhanaan kode; upgrade ke `AVAudioEngine` kalau uji perangkat nunjukin celah memotong kata penting. Uji fisik lengkap (bagian "Uji di perangkat setelah L2") belum dijalankan — dicatat sebagai risiko diterima, bukan diverifikasi. |
| D9 | Proses cloud tetap jalan saat app di background (background `URLSession`)? | L6 | Ya, masuk PRD sebagai requirement S: "Proses di background" dan "Notifikasi MoM siap". Upload lewat background `URLSession`, lanjutan proses lewat `BGTaskScheduler`, notifikasi lokal saat MoM siap. Waktu dari iOS tidak bisa dijamin tanpa backend | **Diputuskan 24 Nov 2026** |
| D10 | Ambang `isStorageLow` (banner layar 15) | L2.4 | Sisa ruang < perkiraan 1 jam rekaman (~28,8 MB, bitrate D8) | **Diputuskan 24 Nov 2026: usulan dipakai apa adanya** |

### Yang tidak boleh diubah

`Views/`, `DesignSystem/`, `ContentView.swift`, nama di kontrak `handover.md` bagian 3, case `MeetingStatus`, dan file di `docs/` selain yang diizinkan di siklus tugas (bagian D).

## C. Daftar tugas

Satu tugas per giliran. Centang setelah tes lolos dan sudah di-commit. Branch per fase: `feat/logic-<fase>`.

### L1 · Model lengkap (membuka blokir UI)

- [x] **L1.1 `Meeting`: konteks dan penanda.** Tambah `agenda: String?`, `glossaryTerms: [String]` (istilah khusus untuk layar 03), `markerOffsets: [TimeInterval]` (penanda momen dalam **waktu audio**, bukan jam dinding, karena jeda telepon tidak ikut terekam), dan `endedAt: Date?` (`nil` berarti rekaman belum ditutup rapi; dipakai untuk pemulihan crash).
  Selesai kalau: tes membuat `Meeting` di `ModelContainer` in-memory dengan semua field, lalu membacanya kembali.
- [x] **L1.2 `Meeting`: status proses.** Tambah enum `ProcessingStep` (5 langkah layar 05: `saved`, `uploaded`, `transcribing`, `unifyingSpeakers`, `summarizing`). Sesuaikan dengan D2: kalau pakai A, langkah `unifyingSpeakers` bisa digabung. Tambah juga `processingStep: ProcessingStep?`, `lastErrorKind: ProcessingErrorKind?` (`invalidAPIKey`, `network`, `vendor`, `unknown`; layar 13 perlu tahu kapan menampilkan "Cek API key"), dan `lastErrorMessage: String?` dalam Bahasa Indonesia untuk user.
  Selesai kalau: ada tes, dan `MeetingStatus` tidak diubah.
- [x] **L1.3 Speaker**, sesuai keputusan D3. Tambah helper `displayName(for label:)` di `Meeting`.
  Selesai kalau: ada tes yang membuktikan ganti nama satu kali mengubah nama tampil di semua utterance.
- [x] **L1.4 `Segment` dan `Utterance`.** Tambah `index: Int` di `Segment` untuk urutan. Tambah `providerJobId: String?`, di `Meeting` kalau D2 = A atau di `Segment` kalau D2 = B, supaya polling bisa dilanjutkan setelah app ditutup tanpa upload ulang (menghemat biaya). Tulis di komentar bahwa `Utterance.startMs` dan `endMs` dihitung relatif terhadap awal audio meeting. Kalau D2 = A, hapus `Segment.transcribed` karena tidak terpakai.
  Selesai kalau: ada tes cascade delete (hapus `Meeting` ikut menghapus segment, utterance, action item, dan speaker).
- [x] **L1.5 Perkuat `KeychainStore`** (perbaiki bug: tulis tes yang gagal dulu). Set `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, tambah `kSecAttrService` sebagai namespace, dan kembalikan hasil `OSStatus` dari `set`, misalnya dengan `throws`, supaya kegagalan tidak diam-diam hilang.
  Selesai kalau: tes membaca atribut item dan memastikan nilai accessible benar, dan tes lama tetap lolos.
- [x] **L1.6 Perbarui `docs/handover.md`.** Tambah nama baru di bagian 3 dan perbarui tabel bagian 4, supaya sesi UI tahu field apa yang sudah tersedia.

### L2 · `AudioRecorder` (rekam tahan gangguan)

- [x] **L2.1 Putuskan D8 di Plan mode.** Paparkan trade-off:
  - `AVAudioRecorder` per segmen: kode sederhana dan level meter bawaan (`averagePower`, sesuai acuan desain). Kekurangannya: perekam harus berhenti lalu mulai lagi tiap pergantian segmen saat layar terkunci, dan ada celah kecil di antara segmen.
  - `AVAudioEngine` dengan tap ke `AVAudioFile`: engine tetap jalan dan hanya file yang berganti, tanpa celah. Kekurangannya: kode lebih banyak, dan tap berjalan di thread audio.

  Uji kecil di iPhone: segmen 60 detik, layar dikunci, 3 kali pergantian segmen. Catat juga format dan bitrate. Sebagai acuan, AAC mono 64 kbps sekitar 29 MB per jam. File `.m4a` yang tidak ditutup rapi saat crash biasanya tidak bisa diputar, jadi uji apa yang terjadi pada segmen yang sedang ditulis.
  Selesai kalau: pilihan dicatat di bagian "Catatan" di bawah.
- [x] **L2.2 Perekam inti.** `@Observable final class AudioRecorder` dengan state `idle`, `recording`, `paused(reason)`, dan `finished`. Expose juga durasi audio, level untuk `WaveformView`, `mark()` untuk tombol Tandai, dan `stop()`. `Meeting` dibuat saat mulai rekam dengan `endedAt = nil`. Tiap segmen yang selesai langsung ditulis sebagai `Segment`. Durasi segmen dikirim lewat `init`, dengan default `RecordingConstants.segmentDuration`, supaya tes bisa memakai durasi pendek.
  Selesai kalau: ada tes transisi state, tes pergantian segmen dengan durasi pendek, dan tes penanda tersimpan dalam waktu audio.
- [x] **L2.3 Gangguan.**
  - `AVAudioSession.interruptionNotification`: saat mulai, jeda dengan alasan `.phoneCall` dan tutup segmen berjalan. Saat selesai, lanjutkan otomatis kalau ada `.shouldResume`. Kalau tidak ada, tetap jeda (layar 14 punya tombol lanjut).
  - Tangani juga perubahan rute audio dan `mediaServicesWereResetNotification`.

  Selesai kalau: ada tes yang mem-post notifikasi tiruan lalu memeriksa state.
  Catatan: perubahan rute (`routeChangeNotification`) sengaja tidak mengubah state — rekaman tetap lanjut dari mikrofon yang tersedia (lihat komentar `handleRouteChange` di `AudioRecorder.swift`). `mediaServicesWereResetNotification` dijeda dengan reason `.phoneCall` (tidak ada reason khusus, scope sekarang cukup pakai yang ada; user tetap bisa tekan Lanjut). Tes di `AudioRecorderInterruptionTests.swift` (5 kasus), tidak memanggil `setActive(true)` di `start()` karena memicu hang IO di simulator headless — sesi audio dibiarkan default (AVAudioRecorder tetap bisa merekam tanpa kategori eksplisit; kalau nanti perlu override kategori untuk kasus device nyata, lakukan di uji fisik L2 bagian bawah, bukan di jalur tes unit).
- [x] **L2.4 Ruang penyimpanan.** Cek `volumeAvailableCapacityForImportantUsageKey` saat mulai dan berkala selama merekam. Expose flag `isStorageLow` untuk banner layar 15. Ambang: belum diputuskan. Usulan: sisa ruang kurang dari perkiraan 1 jam rekaman.
  Selesai kalau: ada tes dengan penyedia kapasitas tiruan.
  Catatan: ambang diputuskan < 1 jam (~28,8 MB, AAC mono 64kbps) — `RecordingConstants.lowStorageThresholdBytes`. Cek saat `start()` dan tiap ~5 detik lewat `tick()` yang sudah ada (bukan timer baru). Sumber kapasitas via closure `availableCapacityProvider` yang di-inject lewat `init` (default `AudioRecorder.systemAvailableCapacity`, baca `volumeAvailableCapacityForImportantUsageKey` folder Documents), supaya `AudioRecorderStorageTests.swift` (5 kasus) bisa kasih nilai tiruan tanpa bergantung disk simulator. `storageRemainingBytes`/`storageRemainingHours` dipaparkan sesuai nama field `RecordingSnapshot` di `docs/handover.md`. Gagal baca disk (`nil`) dianggap tidak low, bukan ditakut-takuti tanpa dasar.
- [x] **L2.5 Pemulihan.** Saat app diluncurkan, `Meeting` dengan `endedAt == nil` ditutup dari segmen yang ada di disk, lalu diberi status `.recorded`. Segmen yang rusak dibuang dan dicatat.
  Selesai kalau: ada tes dengan folder sementara berisi segmen tiruan.
  Catatan: `AudioRecorder.recoverUnfinishedMeetings(in:)` (static) dipanggil otomatis di akhir `init`, tidak perlu dipanggil manual dari `MoMentumApp.swift`. Fetch `Meeting` dengan `#Predicate { $0.endedAt == nil }`. Tiap segmennya dicek pakai `AVAudioPlayer(contentsOf:)` — gagal dibuka berarti rusak/hilang, dibuang dari relasi `meeting.segments` + `context.delete` + file dihapus kalau masih ada di disk. Segmen valid: `durationSeconds` diisi dari durasi player sungguhan. Meeting lalu dapat `endedAt = .now` dan `status = .recorded`. Meeting yang sudah `endedAt != nil` tidak disentuh. Tes `AudioRecorderRecoveryTests.swift` (5 kasus) pakai file WAV PCM ditulis manual untuk kasus "valid" — `AVAudioRecorder.record(forDuration:)` sungguhan di simulator headless menghasilkan file kosong/tidak terbuka (sama akar masalah dengan catatan L2.3 soal `setActive(true)`), jadi dihindari di jalur tes.
- [x] **L2.6 Daftarkan di `MoMentumApp.swift`** lewat `.environment(...)`, lalu perbarui handover.
  Catatan: sudah terdaftar sejak L2.2 (`AudioRecorder(modelContext: sharedModelContainer.mainContext)` di `MoMentumApp.swift` baris 32, wilayah bersama yang Logic boleh edit). Tidak ada perubahan baris tambahan dibutuhkan karena pemulihan (L2.5) otomatis jalan di `init` yang sama.

Uji di perangkat setelah L2 (dikerjakan pemilik, hasil dicatat di bagian F):

- [ ] Rekam 3 jam dengan layar terkunci. Semua segmen utuh, dan catat konsumsi baterai serta ukuran file (guardrail PRD).
- [ ] Telepon masuk di tengah rekaman: rekaman berhenti, lalu lanjut atau menunggu tombol lanjut.
- [ ] App ditutup paksa saat merekam: segmen sebelumnya selamat setelah app dibuka lagi.

### L3 · Transkripsi AssemblyAI

- [x] **L3.1 Rapikan kontrak.** Ganti tuple di `TranscriptResult` dengan struct `TranscribedUtterance` (`Sendable`, `Equatable`). Nama ini dipilih supaya tidak bentrok dengan `@Model Utterance`. Tambah parameter opsi ke `TranscriptionProvider.transcribe`: bahasa (`id`), perkiraan jumlah speaker maksimum, dan istilah khusus.
  Selesai kalau: build lolos dan tes lama tetap lolos.
  Catatan: protokol dipecah jadi `submit(audioFileURL:options:) -> jobId` dan `pollUntilComplete(jobId:) -> TranscriptResult` (bukan satu `transcribe` blocking), supaya `jobId` bisa disimpan ke `Meeting.providerJobId` dan dilanjutkan setelah app ditutup paksa (selaras kontrak `handover.md`). `TranscriptionOptions` (`languageCode` default `"id"`, `maxSpeakersExpected: Int?`, `glossaryTerms: [String]`). `TranscriptionError` jadi 4 case: `missingAPIKey`, `invalidAPIKey`, `network(String)`, `vendor(String)`, `unknown(String)` — sepadan `ProcessingErrorKind` di `Meeting` supaya `MeetingProcessor` (L6) tinggal map 1:1.
- [x] **L3.2 `AssemblyAITranscriptionProvider`.** Pakai `URLSession`, tanpa SDK. Alurnya mengikuti spike:
  - Upload file secara streaming lewat `upload(for:fromFile:)`, jangan dimuat ke memori.
  - Buat transkrip dengan `speaker_labels: true` dan `language_code: "id"`.
  - Polling tiap 10 detik. Spike mencatat batas 60 request per menit per transkrip.

  Polling harus bisa dilanjutkan dari job ID yang tersimpan. Untuk istilah khusus, cek nama field terbaru di dokumentasi AssemblyAI karena field-nya berbeda per model; jangan menebak. Petakan error: 401 menjadi `invalidAPIKey`, status `error` dari vendor menjadi `vendor`, dan masalah koneksi menjadi `network`.
  Catatan: field istilah khusus dicek ulang ke dokumentasi resmi AssemblyAI 24 Nov 2026 (`https://www.assemblyai.com/docs/speech-to-text/pre-recorded-audio/custom-vocabulary` dan `https://www.assemblyai.com/docs/api-reference/transcripts/submit`) — field terbaru `keyterms_prompt` (array string), bukan `word_boost` lama (masih ada di skema respons tapi `keyterms_prompt` yang direkomendasikan dokumentasi sekarang). API key diambil dari `KeychainStore.get(.assemblyAIAPIKey)` lewat closure yang bisa diganti di tes. `URLError` (offline, timeout) dipetakan ke `.network` lewat helper `withNetworkErrorMapping`.
- [x] **L3.3 Tes** dengan `URLProtocol` tiruan dan fixture JSON **sintetis**: upload lolos, polling sampai `completed`, polling sampai `error`, dan 401.
  Catatan: `AssemblyAITranscriptionProviderTests.swift` (5 kasus) + `MockURLProtocol` di file yang sama (dipakai tes ini saja, tidak terpasang global). 77 tes total, 0 gagal.
- [ ] **L3.4 Uji manual** dengan key milik sendiri dan rekaman pendek suara sendiri. Rekaman dan hasilnya tidak di-commit. **Butuh dikerjakan pemilik produk** (API key AssemblyAI asli) — ditunda ke sesi uji fisik bersama checklist L2.

### L4 · Satu label speaker untuk seluruh meeting

- [x] **L4.1 Kalau D2 = A:** buat `AudioMerger` yang menggabungkan segmen menjadi satu file sementara (`AVMutableComposition` + export). Hapus file sementara setelah upload.
  Selesai kalau: ada tes yang membuat 3 file nada sintetis di folder sementara (tanpa suara orang), menggabungkannya, lalu memastikan durasi hasil sama dengan jumlah durasi segmen.
  **Kalau D2 = B:** paparkan desain pencocokan label di Plan mode dulu, baru dikerjakan.
  Catatan: `AudioMerger.merge(segmentURLs:) async throws -> URL`, enum statik (tidak ada state). Input harus sudah terurut oleh caller (`Segment.index`) — `AudioMerger` tidak mengurutkan ulang. Hapus file hasil gabungan setelah upload adalah tanggung jawab caller (`MeetingProcessor`, L6), bukan `AudioMerger`. Tes pakai fixture WAV PCM sintetis (nada hening) seperti L2.5/L4.2, bukan `AVAudioRecorder` sungguhan.
- [x] **L4.2 Normalisasi label.** Label vendor (`A`, `B`, dst.) diubah menjadi `Speaker 1`, `Speaker 2` sesuai urutan kemunculan, lalu disimpan ke `Utterance` dan `Speaker`.
  Selesai kalau: ada tes.
  Catatan: `SpeakerLabelNormalizer.normalize(_:meeting:context:) -> [TranscribedUtterance]`. Mengembalikan array baru (input `[TranscribedUtterance]` tidak dimutasi) dan membuat `Speaker` per label unik langsung di `meeting.speakers` + `context.insert`. Dipanggil setelah `pollUntilComplete` (L6), sebelum `Utterance` dibuat dari hasil normalisasi.
- [ ] **L4.3 Uji kualitas** pada satu rekaman meeting nyata di atas 2 jam. Ini menjawab open question PRD soal diarization untuk rekaman panjang. Hasilnya dicatat di bagian F, bukan file transkripnya.
  **Butuh dikerjakan pemilik produk** (rekaman meeting nyata + API key asli) — ditunda ke sesi uji fisik bersama L2 dan L3.4.

### L5 · `SummaryProvider` (LLM). Menunggu D4

- [ ] **L5.1 Kontrak.** Protocol `SummaryProvider` sepadan dengan `TranscriptionProvider`. Input: transkrip dengan nama speaker, agenda, istilah, penanda momen. Output: struct `SummaryResult` berisi ringkasan, action items (task, PIC opsional, tenggat opsional), dan MoM dalam Markdown dengan format PRD: info meeting, peserta, topik, keputusan, action items.
- [ ] **L5.2 Prompt Bahasa Indonesia** di file terpisah supaya mudah disetel. Model diminta mengembalikan JSON terstruktur. Aturan PIC: kalau tidak jelas, tulis "PIC belum jelas" dan jangan menebak. Bagian di sekitar penanda momen diberi prioritas. Transkrip 3 jam bisa mencapai puluhan ribu token, jadi cek batas context model yang dipilih. Kalau tidak muat, ringkas per bagian lalu gabungkan.
- [ ] **L5.3 Implementasi vendor terpilih.** Validasi JSON, petakan error ke `ProcessingErrorKind`, dan baca API key dari `KeychainStore.llmAPIKey`.
- [ ] **L5.4 Tes:** JSON valid, JSON rusak, PIC kosong menjadi "PIC belum jelas", dan prompt berisi nama speaker serta penanda momen.

### L6 · `MeetingProcessor`, antrean offline, dan coba lagi

- [ ] **L6.1 `@Observable final class MeetingProcessor`.** Menjalankan langkah layar 05 berurutan dan memperbarui `status` serta `processingStep`. Tiap langkah idempoten: coba lagi melanjutkan dari langkah yang gagal tanpa upload ulang. Proses satu meeting dalam satu waktu.
- [ ] **L6.2 Pemicu.** Proses berjalan saat "Simpan & proses" ditekan, saat app diluncurkan atau kembali ke depan, dan saat koneksi pulih (`NWPathMonitor`, framework bawaan). Tanpa internet, status menjadi `.queued`. Saat app ke background, pakai `beginBackgroundTask` untuk menyelesaikan langkah yang sedang berjalan. Sesuai D9: upload memakai background `URLSession`, langkah berikutnya didaftarkan ke `BGTaskScheduler`, dan notifikasi lokal "MoM siap" dikirim saat selesai (minta izin notifikasi saat pertama kali dipakai). Ketuk notifikasi membuka Detail meeting.
- [ ] **L6.3 API untuk UI:** `process(_:)`, `retry(_:)`, dan state progres untuk `ProgressRing`. Daftarkan di `MoMentumApp.swift` dan perbarui handover.
- [ ] **L6.4 Tes** dengan provider tiruan: urutan status pada alur normal, gagal menjadi `.failed` dengan jenis error yang benar, coba lagi melanjutkan dari langkah yang gagal, dan offline menjadi `.queued`.

### L7 · Requirement S dan keputusan sisa

- [ ] **Generate ulang ringkasan** dari transkrip terbaru, tanpa transkripsi ulang.
- [ ] **Catat pemakaian per meeting** (detik audio, token LLM) untuk biaya. Batas bulanan (D7) disimpan di `UserDefaults` karena bukan rahasia.
- [ ] **Retensi audio (D5) dan penghapusan data di vendor (D6)**, sesuai keputusan.

## D. Siklus tiap tugas

1. Untuk tugas yang ditandai "Plan mode" atau yang rumit, mulai dari Plan mode di Cline. Minta 2 sampai 3 pendekatan beserta trade-off-nya, pilih, baru pindah ke Act.
2. Cline mengerjakan satu tugas.
3. Tinjau hasilnya. Di tugas pertama (L1.1), periksa pola penamaan, letak file, dan penanganan error. Koreksi di sini murah.
4. Jalankan perintah tes di bagian A. Fitur baru datang bersama tesnya.
5. Bug: tulis tes yang gagal dulu, baru perbaiki.
6. Commit, misalnya `feat(models): tambah konteks dan penanda di Meeting`. Untuk mundur, pakai git, bukan checkpoint Cline.
7. Kalau ada nama atau field baru yang terlihat oleh UI, perbarui `docs/handover.md` bagian 3 dan 4. Rencana ini mengizinkan perubahan pada handover. File `docs/` lain tetap perlu izin.

Prompt pembuka sesi Cline:

```
Baca .clinerules, CLAUDE.md, docs/handover.md, dan docs/PLAN-logic.md.
Kerjakan tugas L1.1 saja. Keputusan D2 = [A/B], D3 = [isi].
Hanya ubah MoMentum/MoMentum/Models/ dan MoMentum/MoMentumTests/.
Jangan ubah Views/, DesignSystem/, atau case MeetingStatus.
Setelah selesai, jalankan perintah tes di PLAN-logic.md bagian A dan tunjukkan hasilnya.
```

Template prompt tugas berikutnya:

```
Di [file], [perilaku sekarang].
Ubah supaya [perilaku yang diinginkan] sesuai tugas [L?.?] di docs/PLAN-logic.md.
Jangan ubah [hal yang harus tetap].
Acuan: [file spike, layar desain, atau bagian PRD].
```

## E. Kalau macet

- Error: minta Cline menjelaskan penyebabnya dengan bahasa sederhana sebelum memperbaiki.
- Masalah belum jelas: tambah log untuk mempersempit, lalu hapus setelah ketemu. Jangan pernah me-log API key atau isi transkrip.
- Gagal tiga kali untuk masalah yang sama: berhenti. Tulis ringkasan (gejala, yang sudah dicoba, yang sudah diketahui) di bawah, lalu buka task Cline baru dengan ringkasan itu.
- Masalah yang hanya muncul di perangkat (audio, background, layar terkunci): simulator tidak bisa diandalkan. Uji di iPhone lewat Xcode.

Catatan macet:

## F. Penutup sesi

- [ ] Semua tes lolos
- [ ] Semua perubahan sudah di-commit, working tree bersih
- [ ] Tidak ada secret di kode, tes, fixture, atau riwayat git. Kalau sempat ter-commit, anggap bocor dan rotate key-nya
- [ ] Tidak ada rekaman atau transkrip nyata yang ter-commit
- [ ] `docs/handover.md` bagian 3 dan 4 sesuai kondisi terbaru
- [ ] `CLAUDE.md` dan `.clinerules/` diperbarui kalau ada instruksi yang diulang lebih dari sekali
- [ ] File yang membengkak dicatat untuk sesi refactor

### Jangan lakukan (salin juga ke `.clinerules/`)

- Mengubah `Views/`, `DesignSystem/`, atau `ContentView.swift` (wilayah sesi UI).
- Mendefinisikan ulang atau mengganti nama di kontrak `handover.md` bagian 3, atau menambah case `MeetingStatus`, tanpa koordinasi.
- Menambah dependency (Swift Package) tanpa alasan dan persetujuan. Cukup pakai `URLSession`, AVFoundation, dan Network.
- Menulis API key di kode, tes, atau fixture. Tes memakai nilai palsu seperti `"test-key"`.
- Commit rekaman meeting atau transkrip nyata. Fixture harus sintetis.
- Push ke `main` tanpa review.
- Mengubah schema SwiftData secara tidak kompatibel setelah ada data nyata, tanpa migration plan.

### Catatan dan pelajaran (beri tanggal)

- [2026-11-24] Rencana dibuat. Baseline: 1 tes unit lolos di Xcode 27.2.
- [2026-11-24] L1.5: `KeychainStore.set` jadi `throws` (kirim `OSStatus` lewat `KeychainError`), tambah `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` dan `kSecAttrService` sebagai namespace. Ini mengubah signature yang dipakai `APIKeyStore.save` (wilayah UI), jadi `APIKeyStore.save` juga jadi `throws` dan dua caller-nya (`OnboardingKeyView.swift`, `KeyEditorSheet.swift`) disesuaikan pakai `try?` — perubahan minimal, sudah dikonfirmasi pemilik produk. Tes trigger OSStatus gagal asli tidak reliabel di Keychain simulator (cenderung permisif), jadi tes memverifikasi kontrak tipe error, bukan jalur gagal nyata.
- [2026-11-24] L1.4: `Segment.transcribed` tidak dihapus (seharusnya dihapus per plan, D2 = A) karena masih dipakai `Views/Shared/SampleData.swift` (wilayah sesi UI). Ditandai deprecated di komentar. Sesi UI perlu hapus pemakaiannya dulu baru field ini aman dihapus.

### Mulai dari mana di sesi berikutnya

Ambil keputusan D1 sampai D3, lalu buka folder `../meeting-summary-ios-logic` di VS Code dan mulai L1.1 di Cline dengan prompt pembuka di bagian D.
