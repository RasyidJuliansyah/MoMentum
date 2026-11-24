import Foundation

enum RecordingConstants {
    /// Durasi tiap segmen rekaman. 15 menit per keputusan arsitektur (lihat docs/architecture.md).
    /// Konstanta, bukan hardcoded tersebar, supaya gampang diubah kalau limit vendor STT beda.
    static let segmentDuration: TimeInterval = 15 * 60
}
