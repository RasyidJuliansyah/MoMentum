import Foundation

enum RecordingConstants {
    /// Durasi tiap segmen rekaman. 15 menit per keputusan arsitektur (lihat docs/architecture.md).
    /// Konstanta, bukan hardcoded tersebar, supaya gampang diubah kalau limit vendor STT beda.
    static let segmentDuration: TimeInterval = 15 * 60

    /// Bitrate encoder AAC (D8), dipakai `AudioRecorder.startSegment` dan untuk hitung ambang storage.
    static let audioBitRateBps: Int = 64_000

    /// Ambang `isStorageLow` (L2.4): sisa ruang kurang dari perkiraan 1 jam rekaman.
    static let lowStorageThresholdBytes: Int64 = Int64(audioBitRateBps / 8) * 3600
}
