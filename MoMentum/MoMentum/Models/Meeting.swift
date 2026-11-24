import Foundation
import SwiftData

enum MeetingStatus: String, Codable {
    case recorded       // direkam
    case queued         // menunggu
    case processing     // diproses
    case done           // selesai
    case failed         // gagal
}

@Model
final class Meeting {
    var title: String
    var createdAt: Date
    var durationSeconds: Double
    var status: MeetingStatus

    // Konteks meeting (layar 03), dipakai sebagai keyword hint STT dan konteks LLM.
    var agenda: String?
    var glossaryTerms: [String] = []
    /// Penanda momen (tombol Tandai), dalam waktu audio (bukan jam dinding — jeda telepon tidak terekam).
    var markerOffsets: [TimeInterval] = []
    /// `nil` berarti rekaman belum ditutup rapi (dipakai untuk pemulihan setelah crash, lihat L2.5).
    var endedAt: Date?

    // Hasil olahan, diisi setelah transkripsi/LLM selesai
    var summaryText: String?
    var momText: String?

    @Relationship(deleteRule: .cascade, inverse: \Segment.meeting)
    var segments: [Segment] = []

    @Relationship(deleteRule: .cascade, inverse: \ActionItem.meeting)
    var actionItems: [ActionItem] = []

    init(title: String, createdAt: Date = .now, status: MeetingStatus = .recorded) {
        self.title = title
        self.createdAt = createdAt
        self.durationSeconds = 0
        self.status = status
    }
}
