import Foundation

/// `SummaryProvider` untuk Claude lewat Anthropic Messages API (`POST /v1/messages`), tanpa SDK
/// (Swift belum punya SDK resmi). JSON hasil dijamin sesuai skema lewat structured outputs
/// (`output_config.format`), jadi tidak perlu menebak isi teks bebas.
///
/// ponytail: transkrip dikirim utuh tanpa chunking. Konteks model 1M token, cukup untuk meeting
/// berjam-jam; pecah per bagian kalau nanti ada meeting yang melebihi itu.
final class AnthropicSummaryProvider: SummaryProvider {
    static let defaultModel = "claude-opus-5-5"
    static let apiVersion = "2026-10-21"

    private let baseURL: URL
    private let model: String
    private let apiKeyProvider: () -> String?
    private let session: URLSession

    init(
        baseURL: URL = URL(string: "https://api.anthropic.com/v1")!,
        model: String = AnthropicSummaryProvider.defaultModel,
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

        var request = URLRequest(url: baseURL.appendingPathComponent("messages"))
        request.httpMethod = "POST"
        // Ringkasan meeting panjang bisa makan beberapa menit tanpa byte terkirim (non-streaming).
        request.timeoutInterval = 600
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        // Kalau model utama menolak karena klasifikasi keamanan (jarang untuk transkrip meeting),
        // API mengulang di model cadangan dalam panggilan yang sama.
        request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: Self.requestBody(model: model, input: input))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw SummaryError.network(error.localizedDescription)
        }

        try Self.checkResponse(response, data: data)
        return try Self.parse(data)
    }

    static func requestBody(model: String, input: SummaryInput) -> [String: Any] {
        [
            "model": model,
            "max_tokens": 16000,
            "fallbacks": "default",
            "system": SummaryPrompt.system,
            "output_config": [
                "effort": "medium",
                "format": ["type": "json_schema", "schema": schema],
            ],
            "messages": [
                ["role": "user", "content": SummaryPrompt.user(for: input)],
            ],
        ]
    }

    /// Skema sama dengan yang diminta `SummaryPrompt.system`. `dueDate` string kosong berarti tidak disebut.
    static let schema: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["summaryText", "topics", "decisions", "actionItems"],
        "properties": [
            "summaryText": ["type": "string"],
            "topics": ["type": "array", "items": ["type": "string"]],
            "decisions": ["type": "array", "items": ["type": "string"]],
            "actionItems": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["task", "pic", "dueDate"],
                    "properties": [
                        "task": ["type": "string"],
                        "pic": ["type": "string"],
                        "dueDate": ["type": "string"],
                    ],
                ],
            ],
        ],
    ]

    private static func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SummaryError.network("Respons bukan HTTP")
        }
        switch http.statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw SummaryError.invalidAPIKey
        default:
            throw SummaryError.vendor("Ringkasan gagal (\(http.statusCode)): \(errorMessage(from: data))")
        }
    }

    /// `error.message` dari respons error Anthropic, atau potongan body mentah.
    private static func errorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }
        return String((String(data: data, encoding: .utf8) ?? "").prefix(300))
    }

    static func parse(_ data: Data) throws -> SummaryResult {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SummaryError.invalidResponse("Respons Claude tidak terbaca")
        }
        switch json["stop_reason"] as? String {
        case "refusal":
            throw SummaryError.vendor("Claude menolak meringkas transkrip ini. Coba generate ulang.")
        case "max_tokens":
            throw SummaryError.invalidResponse("Ringkasan terpotong karena terlalu panjang. Coba generate ulang.")
        default:
            break
        }
        // Blok `thinking` bisa ada sebelum teks; jawaban JSON ada di blok `text`.
        let blocks = json["content"] as? [[String: Any]] ?? []
        let text = blocks
            .filter { $0["type"] as? String == "text" }
            .compactMap { $0["text"] as? String }
            .joined()
        var result = try OpenAICompatibleSummaryProvider.parseSummaryJSON(text)
        let usage = json["usage"] as? [String: Any]
        result.promptTokens = usage?["input_tokens"] as? Int
        result.completionTokens = usage?["output_tokens"] as? Int
        return result
    }
}

/// Memilih penyedia ringkasan dari key yang diisi user di Pengaturan: key Anthropic (`sk-ant-`)
/// ke Claude, selain itu ke endpoint OpenAI-compatible. User cukup menempel satu key.
final class AutoSummaryProvider: SummaryProvider {
    private let apiKeyProvider: () -> String?
    private let anthropic: SummaryProvider
    private let openAICompatible: SummaryProvider

    init(
        apiKeyProvider: @escaping () -> String? = { KeychainStore.get(.llmAPIKey) },
        anthropic: SummaryProvider = AnthropicSummaryProvider(),
        openAICompatible: SummaryProvider = OpenAICompatibleSummaryProvider(
            baseURL: URL(string: "https://api.openai.com/v1")!,
            model: "gpt-4o-mini"
        )
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.anthropic = anthropic
        self.openAICompatible = openAICompatible
    }

    static func isAnthropicKey(_ key: String?) -> Bool {
        key?.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("sk-ant-") ?? false
    }

    func summarize(_ input: SummaryInput) async throws -> SummaryResult {
        let provider = Self.isAnthropicKey(apiKeyProvider()) ? anthropic : openAICompatible
        return try await provider.summarize(input)
    }
}
