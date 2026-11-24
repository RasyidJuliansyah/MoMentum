import Foundation

/// Isi kartu meeting di Riwayat, dihitung dari `Meeting`. Dipisah dari tampilan supaya bisa dites.
struct MeetingCardContent: Equatable {
    struct Note: Equatable {
        var systemImage: String
        var text: String
    }

    struct ProgressInfo: Equatable {
        var fraction: Double
        var label: String
    }

    var title: String
    var meta: String
    var status: MeetingStatus
    var note: Note?
    var progress: ProgressInfo?
    var showsRetry = false

    init(meeting: Meeting) {
        title = meeting.title
        status = meeting.status
        meta = Self.meta(for: meeting)

        switch meeting.status {
        case .recorded:
            note = Note(systemImage: "tray", text: "Belum diproses. Buka untuk memproses.")
        case .queued:
            note = Note(systemImage: "exclamationmark.triangle", text: "Diproses otomatis begitu ada internet")
        case .processing:
            // TODO(UI): tampilkan bar progres dan nama langkah setelah `Meeting.processingStep`
            // tersedia (PLAN-logic.md L1.2), misalnya "Transkripsi & pemisahan speaker · 62%".
            note = Note(systemImage: "sparkles", text: "Transkrip dan ringkasan sedang dibuat")
        case .failed:
            // TODO(UI): pakai `Meeting.lastErrorMessage` setelah tersedia (PLAN-logic.md L1.2).
            note = Note(systemImage: "exclamationmark.triangle", text: "Proses gagal")
            showsRetry = true
        case .done:
            note = nil
        }
    }

    /// "24 Nov · 1j 58m · 8 segmen" untuk yang belum selesai, "21 Nov · 2j 14m · 3 action items" untuk yang selesai.
    /// Dengan `includeYear`: "24 Nov 2026 · …" (layar 05 dan 13).
    static func meta(for meeting: Meeting, includeYear: Bool = false) -> String {
        let dateStyle = includeYear
            ? Date.FormatStyle.dateTime.day().month(.abbreviated).year()
            : Date.FormatStyle.dateTime.day().month(.abbreviated)
        var parts = [
            meeting.createdAt.formatted(dateStyle.locale(Locale(identifier: "id_ID"))),
            MFormat.duration(meeting.durationSeconds),
        ]
        if meeting.status == .done {
            if !meeting.actionItems.isEmpty {
                parts.append("\(meeting.actionItems.count) action items")
            }
        } else if !meeting.segments.isEmpty {
            parts.append("\(meeting.segments.count) segmen")
        }
        return parts.joined(separator: " · ")
    }
}
