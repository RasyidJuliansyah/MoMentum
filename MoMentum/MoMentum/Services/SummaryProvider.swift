import Foundation

/// Satu action item hasil LLM. `pic` wajib diisi "PIC belum jelas" oleh provider kalau model
/// tidak menyebut nama jelas — jangan menebak (PRD requirement M).
struct SummaryActionItem: Sendable, Equatable {
    var task: String
    var pic: String
    var dueDate: String?
}

/// Hasil ringkasan LLM, sepadan field `Meeting.summaryText`/`topics`/`decisions` dan `@Model ActionItem`.
/// Topik dan keputusan dikirim terstruktur (`[String]`), bukan Markdown mentah, karena UI
/// menyusun MoM teks/Markdown sendiri dari daftar ini (`Views/Detail/MoMDocument.swift`).
struct SummaryResult: Sendable, Equatable {
    var summaryText: String
    var topics: [String]
    var decisions: [String]
    var actionItems: [SummaryActionItem]
    /// Token dari respons chat completions (`usage.prompt_tokens`/`completion_tokens`), untuk
    /// catat pemakaian (L7, D7). `nil` kalau vendor tidak mengembalikan field `usage`.
    var promptTokens: Int?
    var completionTokens: Int?

    init(
        summaryText: String, topics: [String], decisions: [String], actionItems: [SummaryActionItem],
        promptTokens: Int? = nil, completionTokens: Int? = nil
    ) {
        self.summaryText = summaryText
        self.topics = topics
        self.decisions = decisions
        self.actionItems = actionItems
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
    }
}

/// Input untuk `SummaryProvider`. Transkrip sudah pakai nama speaker (hasil `Meeting.displayName(for:)`),
/// bukan label mentah, supaya prompt dan MoM langsung terbaca.
struct SummaryInput: Sendable, Equatable {
    struct Line: Sendable, Equatable {
        var speakerName: String
        var startMs: Int
        var text: String
    }

    var meetingTitle: String
    var agenda: String?
    var glossaryTerms: [String]
    /// Waktu audio (ms) yang ditandai user (tombol Tandai) — diberi prioritas di prompt.
    var markerOffsetsMs: [Int]
    var transcript: [Line]
}

enum SummaryError: Error, Equatable {
    case missingAPIKey
    case invalidAPIKey
    case network(String)
    case vendor(String)
    /// JSON dari model tidak sesuai skema yang diminta (lihat L5.2/L5.3).
    case invalidResponse(String)
    case unknown(String)
}

/// Kontrak adapter LLM, sepadan pola `TranscriptionProvider`. Implementasi pertama (D4):
/// generic "OpenAI-compatible chat completions" — Base URL dan nama model diisi user di
/// Settings (BYOK), bukan dikunci ke satu vendor. Lihat `OpenAICompatibleSummaryProvider`.
protocol SummaryProvider {
    func summarize(_ input: SummaryInput) async throws -> SummaryResult
}
