import Foundation

/// Isi layar 05 Memproses dan 13 Proses gagal, dihitung dari `Meeting`. Dipisah dari tampilan supaya bisa dites.
/// Rekaman dikirim sebagai satu file utuh (PLAN-logic D2 = A), jadi langkahnya per meeting, bukan per segmen.
struct ProcessingContent: Equatable {
    enum StepState: Equatable {
        case done
        case current
        case pending
        case failed
    }

    struct Step: Equatable, Identifiable {
        let id: Int
        let title: String
        var subtitle: String?
        var state: StepState
    }

    static let stepTitles = [
        "Rekaman tersimpan",
        "Rekaman terunggah",
        "Transkripsi & pemisahan speaker",
        "Ringkasan, action items & MoM",
    ]

    /// Judul kartu error di layar 13 sesuai langkah yang gagal.
    static let failureTitles = [
        1: "Upload rekaman gagal",
        2: "Transkripsi gagal",
        3: "Ringkasan gagal dibuat",
    ]

    var title: String
    var meta: String
    var status: MeetingStatus
    /// 0...1, atau `nil` kalau belum diketahui.
    var progress: Double?
    var currentStepIndex: Int?
    var steps: [Step]
    var errorTitle: String?
    var errorMessage: String?

    var isFailed: Bool { status == .failed }

    var percentText: String? {
        progress.map { "\(Int(($0 * 100).rounded()))%" }
    }

    /// "Langkah 3 dari 4".
    var stepCounterText: String? {
        currentStepIndex.map { "Langkah \($0 + 1) dari \(Self.stepTitles.count)" }
    }

    /// Catatan bawah layar 13.
    var retryNote: String {
        "Rekaman tetap aman di iPhone. Coba lagi melanjutkan dari langkah yang gagal, tanpa merekam ulang."
    }

    /// - Parameter currentStepIndex: langkah yang sedang berjalan (atau yang gagal). `nil` kalau belum diketahui.
    init(
        title: String,
        meta: String,
        status: MeetingStatus,
        currentStepIndex: Int? = nil,
        progress: Double? = nil,
        stepSubtitles: [Int: String] = [:],
        errorMessage: String? = nil
    ) {
        self.title = title
        self.meta = meta
        self.status = status
        self.currentStepIndex = status == .done ? nil : currentStepIndex
        self.progress = status == .done ? 1 : progress
        self.errorMessage = errorMessage
        if status == .failed {
            errorTitle = currentStepIndex.flatMap { Self.failureTitles[$0] } ?? "Proses gagal"
        }

        steps = Self.stepTitles.enumerated().map { index, title in
            let state: StepState
            if status == .done {
                state = .done
            } else if let current = currentStepIndex {
                if index < current {
                    state = .done
                } else if index == current {
                    state = status == .failed ? .failed : .current
                } else {
                    state = .pending
                }
            } else {
                // Tanpa info langkah: rekaman yang sudah jadi Meeting pasti sudah tersimpan.
                state = index == 0 ? .done : .pending
            }
            var subtitle = stepSubtitles[index]
            if subtitle == nil, index == 2, state == .current {
                subtitle = "Bahasa Indonesia · diarization aktif"
            }
            return Step(id: index, title: title, subtitle: subtitle, state: state)
        }
    }

    /// - Parameter liveProgress: progres dari `MeetingProcessor` kalau meeting ini sedang diproses.
    init(meeting: Meeting, liveProgress: Double? = nil) {
        var subtitles: [Int: String] = [:]
        if !meeting.segments.isEmpty {
            subtitles[0] = "\(meeting.segments.count) segmen di iPhone"
        }
        let stepIndex = Self.currentStepIndex(for: meeting)
        self.init(
            title: meeting.title,
            meta: MeetingCardContent.meta(for: meeting, includeYear: true),
            status: meeting.status,
            currentStepIndex: stepIndex,
            progress: liveProgress ?? stepIndex.map { Double($0) / Double(Self.stepTitles.count) },
            stepSubtitles: subtitles,
            errorMessage: meeting.status == .failed
                ? (meeting.lastErrorMessage ?? "Ada kendala saat memproses meeting ini.")
                : nil
        )
    }

    /// `Meeting.processingStep` adalah langkah terakhir yang SUDAH selesai, jadi langkah yang sedang
    /// berjalan (atau yang gagal) adalah langkah sesudahnya. Rekaman yang belum pernah diproses: `nil`.
    static func currentStepIndex(for meeting: Meeting) -> Int? {
        switch meeting.processingStep {
        // Belum pernah mulai, atau data lama tanpa info langkah: jangan menebak langkah mana.
        case nil: nil
        case .saved: 1
        case .uploaded: 2
        case .transcribing: 3
        case .summarizing: meeting.status == .done ? nil : 3
        }
    }
}

extension ProcessingContent {
    /// Contoh sesuai Figma layar 05, untuk Preview.
    static let previewProcessing = ProcessingContent(
        title: "Weekly Sync Product",
        meta: "24 Nov 2026 · 1j 58m · 8 segmen",
        status: .processing,
        currentStepIndex: 2,
        progress: 0.62,
        stepSubtitles: [0: "8 segmen · 412 MB di iPhone", 1: "412 MB ke layanan STT"]
    )

    /// Contoh layar 13, untuk Preview.
    static let previewFailed = ProcessingContent(
        title: "Sprint Planning S24",
        meta: "19 Nov 2026 · 2j 36m · 11 segmen",
        status: .failed,
        currentStepIndex: 2,
        errorMessage: "API key STT ditolak (401). Key mungkin kedaluwarsa atau kuotanya habis."
    )
}
