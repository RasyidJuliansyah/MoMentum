import Foundation

/// Implementasi `SummaryProvider` generic untuk endpoint "OpenAI-compatible chat completions"
/// (D4): OpenAI asli, OpenRouter, Ollama lokal, LiteLLM, dll — apa saja yang mengikuti skema
/// `POST {baseURL}/chat/completions`. Base URL dan nama model diisi user di Settings (BYOK),
/// bukan hardcoded ke satu vendor.
///
/// ponytail: transkrip panjang (>2 jam bisa puluhan ribu token) dikirim apa adanya tanpa
/// chunking/ringkas-per-bagian. Kalau nanti kena context limit model, tambah pemotongan
/// transkrip jadi beberapa bagian + ringkas bertahap (lihat catatan L5.2 di PLAN-logic.md).
final class OpenAICompatibleSummaryProvider: SummaryProvider {
    private let baseURL: URL
    private let model: String
    private let apiKeyProvider: () -> String?
    private let session: URLSession

    init(
        baseURL: URL,
        model: String,
        apiKeyProvider: @escaping () -> String? = { KeychainStore.get(.llmAPIKey) },
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.model = model
        self.apiKeyProvider = apiKeyProvider
        self.session = session
    }

    func summarize(_ input: SummaryInput) async throws -> SummaryResult {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw SummaryError.missingAPIKey
        }

        let body: [String: Any] = [
            "model": model,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": SummaryPrompt.system],
                ["role": "user", "content": SummaryPrompt.user(for: input)],
            ],
        ]

        var request = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw SummaryError.network(error.localizedDescription)
        }

        try Self.checkResponse(response, data: data)
        let content = try Self.extractMessageContent(from: data)
        var result = try Self.parseSummaryJSON(content)
        (result.promptTokens, result.completionTokens) = Self.extractUsage(from: data)
        return result
    }

    private static func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SummaryError.network("Respons bukan HTTP")
        }
        guard http.statusCode != 401 else {
            throw SummaryError.invalidAPIKey
        }
        guard http.statusCode < 400 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SummaryError.vendor("Ringkasan gagal (\(http.statusCode)): \(body.prefix(300))")
        }
    }

    /// Ambil `choices[0].message.content` dari respons chat completions standar.
    private static func extractMessageContent(from data: Data) throws -> String {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw SummaryError.invalidResponse("Respons chat completions tidak terbaca")
        }
        return content
    }

    /// `usage.prompt_tokens`/`completion_tokens`, field standar OpenAI-compatible (D7).
    private static func extractUsage(from data: Data) -> (Int?, Int?) {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let usage = json["usage"] as? [String: Any]
        else { return (nil, nil) }
        return (usage["prompt_tokens"] as? Int, usage["completion_tokens"] as? Int)
    }

    private static func parseSummaryJSON(_ content: String) throws -> SummaryResult {
        guard let data = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw SummaryError.invalidResponse("JSON ringkasan tidak valid")
        }
        guard
            let summaryText = json["summaryText"] as? String,
            let rawItems = json["actionItems"] as? [[String: Any]]
        else {
            throw SummaryError.invalidResponse("Field wajib hilang di JSON ringkasan")
        }
        let topics = (json["topics"] as? [String]) ?? []
        let decisions = (json["decisions"] as? [String]) ?? []

        let actionItems = rawItems.compactMap { item -> SummaryActionItem? in
            guard let task = item["task"] as? String else { return nil }
            // PIC kosong/hilang dianggap "PIC belum jelas" — jangan menebak nama (aturan PRD).
            let pic = (item["pic"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "PIC belum jelas"
            let dueDate = item["dueDate"] as? String
            return SummaryActionItem(task: task, pic: pic, dueDate: dueDate)
        }

        return SummaryResult(summaryText: summaryText, topics: topics, decisions: decisions, actionItems: actionItems)
    }
}
