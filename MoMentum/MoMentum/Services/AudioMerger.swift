import Foundation
import AVFoundation

enum AudioMergerError: Error {
    case noSegments
    case exportFailed(String)
}

/// Gabungkan segmen rekaman (15 menit, D8) jadi satu file sementara sebelum upload (D2 = A:
/// satu kali diarization per meeting, bukan per segmen). File sementara dihapus caller setelah
/// upload selesai — lihat `merge(segmentURLs:)` dipanggil dari `MeetingProcessor` (L6).
enum AudioMerger {
    /// Urutan `segmentURLs` menentukan urutan di hasil akhir — caller wajib mengirim sudah
    /// terurut (`Segment.index`), `AudioMerger` tidak mengurutkan ulang.
    static func merge(segmentURLs: [URL]) async throws -> URL {
        guard !segmentURLs.isEmpty else { throw AudioMergerError.noSegments }

        let composition = AVMutableComposition()
        guard let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw AudioMergerError.exportFailed("Gagal membuat track komposisi")
        }

        var cursor = CMTime.zero
        for url in segmentURLs {
            let asset = AVURLAsset(url: url)
            guard let sourceTrack = try await asset.loadTracks(withMediaType: .audio).first else { continue }
            let duration = try await asset.load(.duration)
            try track.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: sourceTrack, at: cursor)
            cursor = CMTimeAdd(cursor, duration)
        }

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-merged.m4a")
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A) else {
            throw AudioMergerError.exportFailed("Gagal membuat export session")
        }

        try await export.export(to: outputURL, as: .m4a)
        return outputURL
    }
}
