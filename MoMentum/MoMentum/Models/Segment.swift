import Foundation
import SwiftData

/// Potongan rekaman berdurasi tetap (lihat `RecordingConstants.segmentDuration`).
@Model
final class Segment {
    var fileName: String        // relatif ke folder dokumen app
    var startedAt: Date
    var durationSeconds: Double
    var index: Int               // urutan segmen (relasi SwiftData tidak menjaga urutan)
    /// Tidak dipakai lagi sejak D2 = A (satu file gabungan per meeting, status transkripsi
    /// ada di `Meeting.processingStep`). Dipertahankan karena masih dipakai
    /// `Views/Shared/SampleData.swift` (wilayah sesi UI) — koordinasikan sebelum dihapus.
    var transcribed: Bool

    var meeting: Meeting?

    @Relationship(deleteRule: .cascade, inverse: \Utterance.segment)
    var utterances: [Utterance] = []

    init(fileName: String, startedAt: Date = .now, index: Int = 0) {
        self.fileName = fileName
        self.startedAt = startedAt
        self.durationSeconds = 0
        self.index = index
        self.transcribed = false
    }
}
