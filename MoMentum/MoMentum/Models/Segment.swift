import Foundation
import SwiftData

/// Potongan rekaman berdurasi tetap (lihat `RecordingConstants.segmentDuration`).
@Model
final class Segment {
    var fileName: String        // relatif ke folder dokumen app
    var startedAt: Date
    var durationSeconds: Double
    var transcribed: Bool

    var meeting: Meeting?

    @Relationship(deleteRule: .cascade, inverse: \Utterance.segment)
    var utterances: [Utterance] = []

    init(fileName: String, startedAt: Date = .now) {
        self.fileName = fileName
        self.startedAt = startedAt
        self.durationSeconds = 0
        self.transcribed = false
    }
}
