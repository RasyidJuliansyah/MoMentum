import Foundation

/// Implementasi `TranscriptionProvider` untuk AssemblyAI. Tanpa SDK, pakai `URLSession`.
/// Alur dan field request mengikuti spike (`spike/stt/stt_spike/providers/assemblyai.py`),
/// dicek ulang ke dokumentasi resmi 24 Nov 2026:
/// https://www.assemblyai.com/docs/pre-recorded-audio/label-speakers
/// https://www.assemblyai.com/docs/api-reference/transcripts/submit
final class AssemblyAITranscriptionProvider: TranscriptionProvider {
    private let baseURL: URL
    private let apiKeyProvider: () -> String?
    private let session: URLSession

    init(
        baseURL: URL = URL(string: "https://api.assemblyai.com")!,
        apiKeyProvider: @escaping () -> String? = { KeychainStore.get(.assemblyAIAPIKey) },
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKeyProvider = apiKeyProvider
        self.session = session
    }

    // MARK: - Submit (upload + buat job)

    func submit(audioFileURL: URL, options: TranscriptionOptions) async throws -> String {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        return try await withNetworkErrorMapping {
            let uploadURL = try await upload(fileURL: audioFileURL, apiKey: apiKey)
            return try await createTranscript(audioURL: uploadURL, options: options, apiKey: apiKey)
        }
    }

    /// Upload streaming dari file (bukan `Data` di memori) — file bisa sampai ratusan MB (D2 = A,
    /// satu file gabungan per meeting).
    private func upload(fileURL: URL, apiKey: String) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("/v2/upload"))
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "authorization")

        let (data, response) = try await session.upload(for: request, fromFile: fileURL)
        try Self.checkResponse(response, data: data, context: "upload")

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let uploadURL = json["upload_url"] as? String
        else {
            throw TranscriptionError.unknown("Respons upload AssemblyAI tidak terbaca")
        }
        return uploadURL
    }

    private func createTranscript(audioURL: String, options: TranscriptionOptions, apiKey: String) async throws -> String {
        var body: [String: Any] = [
            "audio_url": audioURL,
            // Bahasa Indonesia hanya didukung universal-2 (model terbaru belum). Model ditulis jelas
            // karena default vendor bisa berbeda antar akun: https://www.assemblyai.com/llms/models.md
            "speech_models": ["universal-2"],
            "speaker_labels": true,
            "language_code": options.languageCode,
        ]
        if let maxSpeakers = options.maxSpeakersExpected {
            body["speaker_options"] = ["max_speakers_expected": maxSpeakers]
        }
        if !options.glossaryTerms.isEmpty {
            // keyterms_prompt: field terbaru untuk istilah khusus (menggantikan word_boost),
            // lihat https://www.assemblyai.com/docs/speech-to-text/pre-recorded-audio/custom-vocabulary
            body["keyterms_prompt"] = options.glossaryTerms
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("/v2/transcript"))
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "authorization")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        try Self.checkResponse(response, data: data, context: "buat transkrip")

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let jobId = json["id"] as? String
        else {
            throw TranscriptionError.unknown("Respons buat transkrip AssemblyAI tidak terbaca")
        }
        return jobId
    }

    // MARK: - Polling

    /// Batas vendor: 60 request/menit per transkrip (lihat spike), jadi interval 10 detik aman.
    private static let pollInterval: UInt64 = 10 * 1_000_000_000

    func pollUntilComplete(jobId: String) async throws -> TranscriptResult {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        return try await withNetworkErrorMapping {
            while true {
                let (status, json) = try await fetchStatus(jobId: jobId, apiKey: apiKey)
                switch status {
                case "completed":
                    return Self.parseResult(json: json)
                case "error":
                    let message = (json["error"] as? String) ?? "Transkripsi gagal tanpa detail"
                    throw TranscriptionError.vendor(message)
                default:
                    try await Task.sleep(nanoseconds: Self.pollInterval)
                }
            }
        }
    }

    private func fetchStatus(jobId: String, apiKey: String) async throws -> (String, [String: Any]) {
        var request = URLRequest(url: baseURL.appendingPathComponent("/v2/transcript/\(jobId)"))
        request.setValue(apiKey, forHTTPHeaderField: "authorization")

        let (data, response) = try await session.data(for: request)
        try Self.checkResponse(response, data: data, context: "polling")

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let status = json["status"] as? String
        else {
            throw TranscriptionError.unknown("Respons polling AssemblyAI tidak terbaca")
        }
        return (status, json)
    }

    private static func parseResult(json: [String: Any]) -> TranscriptResult {
        let rawUtterances = (json["utterances"] as? [[String: Any]]) ?? []
        let utterances = rawUtterances.compactMap { u -> TranscribedUtterance? in
            guard
                let speaker = u["speaker"] as? String,
                let start = u["start"] as? Int,
                let end = u["end"] as? Int,
                let text = u["text"] as? String
            else { return nil }
            return TranscribedUtterance(speakerLabel: speaker, startMs: start, endMs: end, text: text)
        }
        // audio_duration: detik (Int/Double tergantung respons), dipakai catat pemakaian (L7, D7).
        let audioDuration = (json["audio_duration"] as? Double) ?? (json["audio_duration"] as? Int).map(Double.init)
        return TranscriptResult(provider: "assemblyai", utterances: utterances, audioDurationSeconds: audioDuration)
    }

    // MARK: - Hapus (D6)

    func deleteTranscript(jobId: String) async {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else { return }
        var request = URLRequest(url: baseURL.appendingPathComponent("/v2/transcript/\(jobId)"))
        request.httpMethod = "DELETE"
        request.setValue(apiKey, forHTTPHeaderField: "authorization")
        _ = try? await session.data(for: request)
    }

    // MARK: - Error mapping

    /// Membungkus panggilan `URLSession` supaya `URLError` (offline, timeout, dsb.) dipetakan
    /// ke `.network`, bukan dibiarkan jadi error Foundation mentah.
    private func withNetworkErrorMapping<T>(_ body: () async throws -> T) async throws -> T {
        do {
            return try await body()
        } catch let error as TranscriptionError {
            throw error
        } catch let error as URLError {
            throw TranscriptionError.network(error.localizedDescription)
        }
    }

    private static func checkResponse(_ response: URLResponse, data: Data, context: String) throws {
        guard let http = response as? HTTPURLResponse else {
            throw TranscriptionError.network("Respons \(context) bukan HTTP")
        }
        guard http.statusCode != 401 else {
            throw TranscriptionError.invalidAPIKey
        }
        guard http.statusCode < 400 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw TranscriptionError.vendor("\(context) gagal (\(http.statusCode)): \(body.prefix(300))")
        }
    }
}
