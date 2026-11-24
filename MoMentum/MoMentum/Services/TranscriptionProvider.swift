import Foundation

/// Hasil transkripsi satu segmen audio, sepadan dengan `TranscriptResult` di spike Python.
struct TranscriptResult {
    var provider: String
    var utterances: [(speakerLabel: String, startMs: Int, endMs: Int, text: String)]
}

enum TranscriptionError: Error {
    case missingAPIKey
    case requestFailed(String)
}

/// Kontrak adapter STT. Vendor diganti dengan implementasi baru tanpa mengubah UI/caller.
/// Implementasi pertama: AssemblyAI (lihat docs/architecture.md untuk alasan pemilihan).
protocol TranscriptionProvider {
    func transcribe(audioFileURL: URL) async throws -> TranscriptResult
}
