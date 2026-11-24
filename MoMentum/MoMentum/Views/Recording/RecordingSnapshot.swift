import Foundation

/// Semua yang ditampilkan layar Merekam (02, 14, 15), terlepas dari sumber datanya.
/// Nanti diisi dari `AudioRecorder` (sesi Logic, PLAN-logic.md L2), sekarang dari `RecordingDemoDriver`.
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
    var isStorageLow = false

    var isRecording: Bool { phase == .recording }
}

extension RecordingSnapshot {
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
