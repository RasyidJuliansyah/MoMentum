import Foundation

/// Satu ucapan dari satu speaker, hasil diarization. Nama "Transcribed" (bukan "Utterance")
/// supaya tidak bentrok dengan `@Model Utterance` di Models/. `startMs`/`endMs` relatif
/// terhadap awal audio meeting (sama konvensi dengan `Utterance.startMs`/`endMs`).
struct TranscribedUtterance: Sendable, Equatable {
    var speakerLabel: String
    var startMs: Int
    var endMs: Int
    var text: String
}

/// Hasil transkripsi, sepadan dengan `TranscriptResult` di spike Python.
struct TranscriptResult: Sendable, Equatable {
    var provider: String
    var utterances: [TranscribedUtterance]
}

/// Opsi transkripsi (layar 03: agenda/istilah khusus). Semua opsional kecuali bahasa —
/// vendor pakai heuristik sendiri kalau `maxSpeakersExpected`/`glossaryTerms` kosong.
struct TranscriptionOptions: Sendable, Equatable {
    var languageCode: String
    var maxSpeakersExpected: Int?
    var glossaryTerms: [String]

    init(languageCode: String = "id", maxSpeakersExpected: Int? = nil, glossaryTerms: [String] = []) {
        self.languageCode = languageCode
        self.maxSpeakersExpected = maxSpeakersExpected
        self.glossaryTerms = glossaryTerms
    }
}

/// Dipetakan dari hasil vendor supaya `MeetingProcessor` (L6) bisa isi `Meeting.lastErrorKind`
/// tanpa tahu detail vendor.
enum TranscriptionError: Error, Equatable {
    case missingAPIKey
    case invalidAPIKey
    case network(String)
    case vendor(String)
    case unknown(String)
}

/// Kontrak adapter STT. Vendor diganti dengan implementasi baru tanpa mengubah UI/caller.
/// Implementasi pertama: AssemblyAI (lihat docs/architecture.md untuk alasan pemilihan).
/// Dipecah jadi submit + poll (bukan satu `transcribe` blocking) supaya job ID bisa disimpan
/// (`Meeting.providerJobId`) dan polling dilanjutkan setelah app ditutup paksa (L3.2).
protocol TranscriptionProvider {
    func submit(audioFileURL: URL, options: TranscriptionOptions) async throws -> String
    func pollUntilComplete(jobId: String) async throws -> TranscriptResult
}
