import Foundation

/// Isi layar 05 Memproses dan 13 Proses gagal, dihitung dari `Meeting`. Dipisah dari tampilan supaya bisa dites.
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

    enum SegmentState: Equatable {
        case done
        case failed
        case pending
    }

    /// Urutan langkah sesuai Figma layar 05.
    static let stepTitles = [
        "Rekaman tersimpan",
        "Segmen terunggah",
        "Transkripsi & pemisahan speaker",
        "Menyamakan label speaker antarsegmen",
        "Ringkasan, action items & MoM",
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
    /// Status tiap segmen berurutan (layar 13).
    var segments: [SegmentState]

    var isFailed: Bool { status == .failed }

    var percentText: String? {
        progress.map { "\(Int(($0 * 100).rounded()))%" }
    }

    /// "Langkah 3 dari 5".
    var stepCounterText: String? {
        currentStepIndex.map { "Langkah \($0 + 1) dari \(Self.stepTitles.count)" }
    }

    func count(of state: SegmentState) -> Int {
        segments.filter { $0 == state }.count
    }

    /// Catatan bawah layar 13, misalnya "… Coba lagi hanya mengirim segmen 7–11."
    var retryNote: String {
        guard let first = segments.firstIndex(where: { $0 != .done }) else {
            return "Rekaman tetap aman di iPhone. Coba lagi tidak perlu merekam ulang."
        }
        let range = first + 1 == segments.count ? "\(first + 1)" : "\(first + 1)–\(segments.count)"
        return "Rekaman tetap aman di iPhone. Coba lagi hanya mengirim segmen \(range)."
    }

    /// - Parameter currentStepIndex: langkah yang sedang berjalan (atau yang gagal). `nil` kalau belum diketahui.
    init(
        title: String,
        meta: String,
        status: MeetingStatus,
        currentStepIndex: Int? = nil,
        progress: Double? = nil,
        stepSubtitles: [Int: String] = [:],
        errorTitle: String? = nil,
        errorMessage: String? = nil,
        segments: [SegmentState] = []
    ) {
        self.title = title
        self.meta = meta
        self.status = status
        self.currentStepIndex = status == .done ? nil : currentStepIndex
        self.progress = status == .done ? 1 : progress
        self.errorTitle = errorTitle
        self.errorMessage = errorMessage
        self.segments = segments

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

    init(meeting: Meeting) {
        let ordered = meeting.segments.sorted { $0.startedAt < $1.startedAt }
        let firstUnfinished = ordered.firstIndex { !$0.transcribed }
        let segments: [SegmentState] = ordered.enumerated().map { index, segment in
            if segment.transcribed { return .done }
            // Proses berjalan berurutan, jadi segmen pertama yang belum selesai dianggap tempat berhenti.
            return meeting.status == .failed && index == firstUnfinished ? .failed : .pending
        }

        var subtitles: [Int: String] = [:]
        if !ordered.isEmpty {
            subtitles[0] = "\(ordered.count) segmen di iPhone"
        }

        var errorTitle: String?
        if meeting.status == .failed {
            errorTitle = firstUnfinished.map { "Transkripsi berhenti di segmen \($0 + 1)" } ?? "Proses gagal"
        }

        // TODO(UI): isi currentStepIndex, progress, dan errorMessage dari Meeting setelah
        // PLAN-logic.md L1.2 menambahkan langkah proses dan error terakhir.
        self.init(
            title: meeting.title,
            meta: MeetingCardContent.meta(for: meeting, includeYear: true),
            status: meeting.status,
            stepSubtitles: subtitles,
            errorTitle: errorTitle,
            errorMessage: meeting.status == .failed ? "Ada kendala saat memproses meeting ini." : nil,
            segments: segments
        )
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
        stepSubtitles: [0: "8 segmen · 412 MB di iPhone", 1: "8/8 ke layanan STT"]
    )

    /// Contoh sesuai Figma layar 13, untuk Preview.
    static let previewFailed = ProcessingContent(
        title: "Sprint Planning S24",
        meta: "19 Nov 2026 · 2j 36m · 11 segmen",
        status: .failed,
        errorTitle: "Transkripsi berhenti di segmen 7",
        errorMessage: "API key STT ditolak (401). Key mungkin kedaluwarsa atau kuotanya habis.",
        segments: Array(repeating: .done, count: 6) + [.failed] + Array(repeating: .pending, count: 4)
    )
}
