import Foundation
import SwiftData

/// Satu baris transkrip: label/nama speaker + teks yang dia ucapkan.
@Model
final class Utterance {
    var speakerLabel: String   // "Speaker 1" default, diganti user jadi nama asli
    var startMs: Int
    var endMs: Int
    var text: String

    var segment: Segment?

    init(speakerLabel: String, startMs: Int, endMs: Int, text: String) {
        self.speakerLabel = speakerLabel
        self.startMs = startMs
        self.endMs = endMs
        self.text = text
    }
}
