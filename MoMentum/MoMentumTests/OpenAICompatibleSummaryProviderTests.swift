import XCTest
@testable import MoMentum

// L5.4: JSON valid, JSON rusak, PIC kosong -> "PIC belum jelas", prompt berisi nama speaker + penanda.
final class OpenAICompatibleSummaryProviderTests: XCTestCase {

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func makeProvider(apiKey: String? = "test-key") -> OpenAICompatibleSummaryProvider {
        OpenAICompatibleSummaryProvider(
            baseURL: URL(string: "https://api.example.com/v1")!,
            model: "gpt-fake",
            apiKeyProvider: { apiKey },
            session: makeSession()
        )
    }

    private func sampleInput() -> SummaryInput {
        SummaryInput(
            meetingTitle: "Daily Standup",
            agenda: "Update progres sprint",
            glossaryTerms: ["sprint", "backlog"],
            markerOffsetsMs: [90_000],
            transcript: [
                SummaryInput.Line(speakerName: "Budi", startMs: 0, text: "Progres kita di mana?"),
                SummaryInput.Line(speakerName: "Ani", startMs: 5000, text: "Saya selesai fitur login."),
            ]
        )
    }

    private func chatCompletionResponse(content: String) -> Data {
        let escaped = content.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
        let body = """
        {"choices":[{"message":{"role":"assistant","content":"\(escaped)"}}]}
        """
        return Data(body.utf8)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testValidJSONParsedIntoSummaryResult() async throws {
        let json = """
        {"summaryText":"Ringkasan singkat.","actionItems":[{"task":"Perbaiki bug login","pic":"Ani","dueDate":"Jumat depan"}],"momMarkdown":"# MoM"}
        """
        MockURLProtocol.requestHandler = { _ in (200, self.chatCompletionResponse(content: json)) }

        let result = try await makeProvider().summarize(sampleInput())

        XCTAssertEqual(result.summaryText, "Ringkasan singkat.")
        XCTAssertEqual(result.actionItems.count, 1)
        XCTAssertEqual(result.actionItems.first?.pic, "Ani")
        XCTAssertEqual(result.actionItems.first?.dueDate, "Jumat depan")
        XCTAssertEqual(result.momMarkdown, "# MoM")
    }

    func testMalformedJSONThrowsInvalidResponse() async throws {
        MockURLProtocol.requestHandler = { _ in (200, self.chatCompletionResponse(content: "bukan json valid")) }

        do {
            _ = try await makeProvider().summarize(sampleInput())
            XCTFail("Harus melempar invalidResponse")
        } catch SummaryError.invalidResponse {
            // sesuai harapan
        }
    }

    func testMissingPICDefaultsToBelumJelas() async throws {
        let json = """
        {"summaryText":"Ringkasan.","actionItems":[{"task":"Tugas tanpa PIC jelas","dueDate":null}],"momMarkdown":"# MoM"}
        """
        MockURLProtocol.requestHandler = { _ in (200, self.chatCompletionResponse(content: json)) }

        let result = try await makeProvider().summarize(sampleInput())

        XCTAssertEqual(result.actionItems.first?.pic, "PIC belum jelas")
    }

    func testPromptContainsSpeakerNamesAndMarkerTimestamp() {
        let prompt = SummaryPrompt.user(for: sampleInput())

        XCTAssertTrue(prompt.contains("Budi"), "prompt harus berisi nama speaker")
        XCTAssertTrue(prompt.contains("Ani"), "prompt harus berisi nama speaker")
        XCTAssertTrue(prompt.contains("01:30"), "prompt harus berisi timestamp momen ditandai (90 detik)")
    }

    func test401ResponseThrowsInvalidAPIKey() async throws {
        MockURLProtocol.requestHandler = { _ in (401, Data(#"{"error":"invalid key"}"#.utf8)) }

        do {
            _ = try await makeProvider().summarize(sampleInput())
            XCTFail("Harus melempar invalidAPIKey")
        } catch SummaryError.invalidAPIKey {
            // sesuai harapan
        }
    }

    func testSubmitWithoutAPIKeyThrowsMissingAPIKey() async throws {
        do {
            _ = try await makeProvider(apiKey: nil).summarize(sampleInput())
            XCTFail("Harus melempar missingAPIKey")
        } catch SummaryError.missingAPIKey {
            // sesuai harapan
        }
    }
}
