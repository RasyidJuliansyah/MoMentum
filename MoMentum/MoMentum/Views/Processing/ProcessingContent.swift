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
        var state: StepState
    }

    /// Urutan langkah sesuai design-handoff.md bagian 7.
    static let stepTitles = [
        "Rekaman tersimpan",
        "Segmen terunggah",
        "Transkripsi & pemisahan speaker",
        "Penyamaan label speaker",
        "Ringkasan, action items & MoM",
    ]

    var title: String
    var meta: String
    var status: MeetingStatus
    /// 0...1, atau `nil` kalau belum diketahui.
    var progress: Double?
    var steps: [Step]
    var errorMessage: String?

    var isFailed: Bool { status == .failed }

    var percentText: String? {
        progress.map { "\(Int(($0 * 100).rounded()))%" }
    }

    /// - Parameter currentStepIndex: langkah yang sedang berjalan (atau yang gagal). `nil` kalau belum diketahui.
    init(
        title: String,
        meta: String,
        status: MeetingStatus,
        currentStepIndex: Int? = nil,
        progress: Double? = nil,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.meta = meta
        self.status = status
        self.errorMessage = errorMessage
        self.progress = status == .done ? 1 : progress

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
            return Step(id: index, title: title, state: state)
        }
    }

    init(meeting: Meeting) {
        // TODO(UI): isi currentStepIndex, progress, dan errorMessage dari Meeting setelah
        // PLAN-logic.md L1.2 menambahkan langkah proses dan error terakhir.
        self.init(
            title: meeting.title,
            meta: MeetingCardContent.meta(for: meeting),
            status: meeting.status
        )
    }
}

extension ProcessingContent {
    /// Contoh sesuai layar Riwayat di Figma ("Transkripsi & pemisahan speaker · 62%"), untuk Preview.
    static let previewProcessing = ProcessingContent(
        title: "Weekly Sync Product",
        meta: "24 Nov · 1j 58m · 8 segmen",
        status: .processing,
        currentStepIndex: 2,
        progress: 0.62
    )

    static let previewFailed = ProcessingContent(
        title: "Sprint Planning S24",
        meta: "19 Nov · 2j 36m",
        status: .failed,
        currentStepIndex: 1,
        errorMessage: "Upload segmen 7 gagal. Koneksi terputus saat mengirim ke server transkripsi."
    )
}
