import XCTest
@testable import MoMentum

/// Request ke Messages API, parsing respons (blok thinking + text, usage), dan error.
final class AnthropicSummaryProviderTests: XCTestCase {

    private func makeProvider(apiKey: String? = "sk-ant-PALSU") -> AnthropicSummaryProvider {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return AnthropicSummaryProvider(apiKeyProvider: { apiKey }, session: URLSession(configuration: config))
    }

    private let input = SummaryInput(
        meetingTitle: "Weekly Sync",
        agenda: nil,
        glossaryTerms: [],
        markerOffsetsMs: [],
        transcript: [SummaryInput.Line(speakerName: "Speaker 1", startMs: 0, text: "Halo semua.")]
    )

    private func messageResponse(json: String, stopReason: String = "end_turn") -> Data {
        let response: [String: Any] = [
            "type": "message",
            "stop_reason": stopReason,
            "content": [
                ["type": "thinking", "thinking": ""],
                ["type": "text", "text": json],
            ],
            "usage": ["input_tokens": 1200, "output_tokens": 340],
        ]
        return try! JSONSerialization.data(withJSONObject: response)
    }

    private static func body(of request: URLRequest) -> [String: Any] {
        var data = request.httpBody ?? Data()
        if data.isEmpty, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: buffer.count)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
        }
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testRequestUsesMessagesAPIWithStructuredOutput() async throws {
        var captured: URLRequest?
        let json = #"{"summaryText":"S","topics":[],"decisions":[],"actionItems":[]}"#
        MockURLProtocol.requestHandler = { request in
            captured = request
            return (200, self.messageResponse(json: json))
        }

        _ = try await makeProvider().summarize(input)

        let request = try XCTUnwrap(captured)
        XCTAssertEqual(request.url?.absoluteString, "https://api.anthropic.com/v1/messages")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-api-key"), "sk-ant-PALSU")
        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-version"), AnthropicSummaryProvider.apiVersion)
        let body = Self.body(of: request)
        XCTAssertEqual(body["model"] as? String, "claude-opus-5-5")
        let format = (body["output_config"] as? [String: Any])?["format"] as? [String: Any]
        XCTAssertEqual(format?["type"] as? String, "json_schema")
    }

    func testParsesTextBlockAfterThinkingAndUsage() async throws {
        let json = """
        {"summaryText":"Ringkasan.","topics":["Roadmap"],"decisions":["Rilis Jumat"],"actionItems":[{"task":"Siapkan demo","pic":"Dina","dueDate":""},{"task":"Cek SNBP","pic":"","dueDate":"Senin"}]}
        """
        MockURLProtocol.requestHandler = { _ in (200, self.messageResponse(json: json)) }

        let result = try await makeProvider().summarize(input)

        XCTAssertEqual(result.summaryText, "Ringkasan.")
        XCTAssertEqual(result.topics, ["Roadmap"])
        XCTAssertEqual(result.decisions, ["Rilis Jumat"])
        XCTAssertNil(result.actionItems[0].dueDate, "dueDate kosong berarti tidak disebut")
        XCTAssertEqual(result.actionItems[1].pic, "PIC belum jelas")
        XCTAssertEqual(result.actionItems[1].dueDate, "Senin")
        XCTAssertEqual(result.promptTokens, 1200)
        XCTAssertEqual(result.completionTokens, 340)
    }

    func testRefusalThrowsVendorError() async {
        MockURLProtocol.requestHandler = { _ in (200, self.messageResponse(json: "", stopReason: "refusal")) }
        do {
            _ = try await makeProvider().summarize(input)
            XCTFail("Harus melempar")
        } catch SummaryError.vendor {
        } catch {
            XCTFail("Error salah: \(error)")
        }
    }

    func test401ThrowsInvalidAPIKey() async {
        MockURLProtocol.requestHandler = { _ in
            (401, Data(#"{"type":"error","error":{"type":"authentication_error","message":"invalid x-api-key"}}"#.utf8))
        }
        do {
            _ = try await makeProvider().summarize(input)
            XCTFail("Harus melempar")
        } catch {
            XCTAssertEqual(error as? SummaryError, .invalidAPIKey)
        }
    }

    func testMissingKeyThrowsWithoutRequest() async {
        MockURLProtocol.requestHandler = { _ in
            XCTFail("Tidak boleh ada request tanpa key")
            return (500, Data())
        }
        do {
            _ = try await makeProvider(apiKey: nil).summarize(input)
            XCTFail("Harus melempar")
        } catch {
            XCTAssertEqual(error as? SummaryError, .missingAPIKey)
        }
    }

    // MARK: AutoSummaryProvider

    func testAutoProviderRoutesByKeyPrefix() async throws {
        let anthropic = RecordingSummaryProvider()
        let openAI = RecordingSummaryProvider()

        _ = try await AutoSummaryProvider(apiKeyProvider: { " sk-ant-abc" }, anthropic: anthropic, openAICompatible: openAI).summarize(input)
        XCTAssertEqual(anthropic.callCount, 1)
        XCTAssertEqual(openAI.callCount, 0)

        _ = try await AutoSummaryProvider(apiKeyProvider: { "sk-proj-abc" }, anthropic: anthropic, openAICompatible: openAI).summarize(input)
        XCTAssertEqual(anthropic.callCount, 1)
        XCTAssertEqual(openAI.callCount, 1)
    }
}

private final class RecordingSummaryProvider: SummaryProvider {
    var callCount = 0

    func summarize(_ input: SummaryInput) async throws -> SummaryResult {
        callCount += 1
        return SummaryResult(summaryText: "", topics: [], decisions: [], actionItems: [])
    }
}
