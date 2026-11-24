import Foundation
import SwiftData

/// D5: hapus file audio (bukan transkrip/MoM) setelah `retentionDays` sejak `Meeting.processedAt`.
/// Dipanggil sekali saat app diluncurkan (mirip `AudioRecorder.recoverUnfinishedMeetings`).
/// `retentionDays == 0` berarti selamanya (tidak pernah dihapus) — sesuai konvensi
/// `AppStorageKey.audioRetentionDays` (wilayah UI, nilai dibaca lewat `UserDefaults` di caller).
enum AudioRetentionCleaner {
    static func deleteExpiredAudio(in context: ModelContext, retentionDays: Int, now: Date = .now) {
        guard retentionDays > 0 else { return }
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: now) else { return }

        let candidates = (try? context.fetch(
            FetchDescriptor<Meeting>(predicate: #Predicate { $0.processedAt != nil })
        )) ?? []

        for meeting in candidates {
            guard let processedAt = meeting.processedAt, processedAt < cutoff else { continue }
            for segment in meeting.segments {
                let url = AudioRecorder.segmentsDirectory().appendingPathComponent(segment.fileName)
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
