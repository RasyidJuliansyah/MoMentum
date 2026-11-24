import Foundation
import SwiftData

/// Label vendor (`A`, `B`, dst.) tidak ramah untuk ditampilkan ke user. L4.2: normalisasi
/// jadi "Speaker 1", "Speaker 2" sesuai urutan kemunculan pertama, lalu simpan ke `Utterance`
/// dan buat `Speaker` per meeting (D3) supaya ganti nama bisa langsung dipakai.
enum SpeakerLabelNormalizer {
    /// Mengubah label mentah di `utterances` jadi label ternormalisasi secara in-place
    /// (array baru dikembalikan, input tidak diubah) dan membuat `Speaker` di `meeting`.
    /// Dipanggil setelah `TranscriptionProvider.pollUntilComplete` selesai (L6).
    static func normalize(_ utterances: [TranscribedUtterance], meeting: Meeting, context: ModelContext) -> [TranscribedUtterance] {
        var labelMap: [String: String] = [:]
        var nextIndex = 1

        var normalized: [TranscribedUtterance] = []
        normalized.reserveCapacity(utterances.count)

        for utterance in utterances {
            let rawLabel = utterance.speakerLabel
            let normalizedLabel: String
            if let existing = labelMap[rawLabel] {
                normalizedLabel = existing
            } else {
                normalizedLabel = "Speaker \(nextIndex)"
                labelMap[rawLabel] = normalizedLabel
                nextIndex += 1

                let speaker = Speaker(label: normalizedLabel)
                meeting.speakers.append(speaker)
                context.insert(speaker)
            }

            var copy = utterance
            copy.speakerLabel = normalizedLabel
            normalized.append(copy)
        }

        return normalized
    }
}
