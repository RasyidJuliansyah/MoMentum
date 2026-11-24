import Foundation
import SwiftData

/// Nama tampil untuk satu label speaker vendor (D3). `Utterance.speakerLabel` tetap
/// label mentah ("Speaker 1"); ganti nama cukup ubah `name` di sini sekali, berlaku
/// untuk semua utterance dengan label yang sama lewat `Meeting.displayName(for:)`.
@Model
final class Speaker {
    var label: String       // "Speaker 1", cocok dengan Utterance.speakerLabel
    var name: String?       // nama asli, nil berarti belum diganti user

    var meeting: Meeting?

    init(label: String, name: String? = nil) {
        self.label = label
        self.name = name
    }
}
