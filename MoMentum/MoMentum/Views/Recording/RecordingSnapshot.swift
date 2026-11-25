import Foundation

/// Semua yang ditampilkan layar Merekam (02, 14, 15), terlepas dari sumber datanya.
/// Diisi dari `AudioRecorder` (lihat `init(recorder:title:agenda:)`).
struct RecordingSnapshot: Equatable {
    enum PauseReason: Equatable {
        case user
        case phoneCall
    }

    enum Phase: Equatable {
        case recording
        case paused(PauseReason)
    }

    var title: String
    var agenda: String?
    var phase: Phase = .recording
    /// Durasi audio yang sudah terekam (jeda tidak dihitung).
    var elapsed: TimeInterval = 0
    var segmentNumber: Int = 1
    /// Level audio terbaru 0...1, paling baru di akhir.
    var levels: [Double] = []
    /// Penanda momen dalam waktu audio.
    var markers: [TimeInterval] = []
    /// Perkiraan sisa ruang dalam jam rekaman. `nil` kalau belum diketahui.
    var storageRemainingHours: Int?
    /// Sisa ruang dalam byte, untuk banner layar 15 ("tinggal 1,2 GB").
    var storageRemainingBytes: Int64?
    var isStorageLow = false

    var isRecording: Bool { phase == .recording }

    /// Level per detik dari `AudioRecorder` (tick 0,2 detik).
    static let levelsPerSecond = 5
    /// Lama hening total sebelum peringatan muncul.
    static let silenceWarningSeconds = 3

    /// Mikrofon hanya mengirim hening digital (level 0 = -60 dB ke bawah; iOS mengirim -120 dB) selama
    /// beberapa detik. Ruangan sepi pun biasanya masih -50 dB, jadi ini tanda iOS memblokir mikrofon:
    /// iPhone sedang di-mirror ke Mac (iPhone Mirroring), terkunci saat mulai merekam, atau perekam gagal.
    var isInputSilent: Bool {
        let window = Self.levelsPerSecond * Self.silenceWarningSeconds
        return isRecording && levels.count >= window && levels.suffix(window).allSatisfy { $0 < 0.01 }
    }
}

extension RecordingSnapshot {
    /// Batas level yang dibawa ke layar (±24 detik). Perekam menyimpan semua level; layar hanya butuh ujungnya.
    static let visibleLevelCount = 120

    init(recorder: AudioRecorder, title: String, agenda: String?) {
        self.init(title: recorder.meeting?.title ?? title, agenda: recorder.meeting?.agenda ?? agenda)
        switch recorder.state {
        case .paused(.user), .finished: phase = .paused(.user)
        case .paused(.phoneCall): phase = .paused(.phoneCall)
        case .idle, .recording: phase = .recording
        }
        elapsed = recorder.elapsed
        segmentNumber = recorder.segmentNumber
        levels = Array(recorder.levels.suffix(Self.visibleLevelCount))
        markers = recorder.markers
        storageRemainingHours = recorder.storageRemainingHours
        storageRemainingBytes = recorder.storageRemainingBytes
        isStorageLow = recorder.isStorageLow
    }

    /// Contoh sesuai layar 02 di Figma, untuk Preview.
    static let preview = RecordingSnapshot(
        title: "Weekly Sync Product",
        agenda: "review sprint & roadmap Q1",
        elapsed: 4368,
        segmentNumber: 5,
        levels: WaveformView.decorativeLevels(count: 28, seed: 1),
        markers: [2530, 3933],
        storageRemainingHours: 140
    )
}
