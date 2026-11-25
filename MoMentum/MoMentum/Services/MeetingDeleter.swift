import Foundation
import SwiftData

/// Hapus satu meeting beserta file audionya di iPhone. Segmen, transkrip, speaker, dan action items
/// ikut terhapus lewat `deleteRule: .cascade` di `Meeting`.
enum MeetingDeleter {
    static func delete(_ meeting: Meeting, in context: ModelContext) {
        for segment in meeting.segments {
            let url = AudioRecorder.segmentsDirectory().appendingPathComponent(segment.fileName)
            try? FileManager.default.removeItem(at: url)
        }
        context.delete(meeting)
        try? context.save()
    }
}
