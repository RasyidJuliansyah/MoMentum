import XCTest
@testable import MoMentum

// L3.3: tes AssemblyAITranscriptionProvider dengan URLProtocol tiruan dan fixture JSON sintetis.
final class AssemblyAITranscriptionProviderTests: XCTestCase {

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func makeProvider(apiKey: String? = "test-key") -> AssemblyAITranscriptionProvider {
        AssemblyAITranscriptionProvider(apiKeyProvider: { apiKey }, session: makeSession())
    }

    private func tempAudioFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
        try Data("audio sintetis".utf8).write(to: url)
        return url
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testSubmitWithoutAPIKeyThrowsMissingAPIKey() async throws {
        let provider = makeProvider(apiKey: nil)
        do {
            _ = try await provider.submit(audioFileURL: try tempAudioFile(), options: TranscriptionOptions())
            XCTFail("Harus melempar missingAPIKey")
        } catch TranscriptionError.missingAPIKey {
            // sesuai harapan
        }
    }

    func testSubmitUploadThenCreateTranscriptSucceeds() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if request.url?.path == "/v2/upload" {
                let body = #"{"upload_url":"https://cdn.assemblyai.com/upload/fake-id"}"#
                return (200, Data(body.utf8))
            }
            if request.url?.path == "/v2/transcript" {
                let body = #"{"id":"job-123","status":"queued"}"#
                return (200, Data(body.utf8))
            }
            XCTFail("URL tak terduga: \(request.url?.path ?? "")")
            return (500, Data())
        }

        let provider = makeProvider()
        let jobId = try await provider.submit(audioFileURL: try tempAudioFile(), options: TranscriptionOptions())

        XCTAssertEqual(jobId, "job-123")
        XCTAssertEqual(callCount, 2)
    }

    func testPollUntilCompleteReturnsUtterances() async throws {
        MockURLProtocol.requestHandler = { _ in
            let body = """
            {"status":"completed","utterances":[
                {"speaker":"A","start":0,"end":1200,"text":"Halo semua"},
                {"speaker":"B","start":1300,"end":2000,"text":"Selamat pagi"}
            ]}
            """
            return (200, Data(body.utf8))
        }

        let provider = makeProvider()
        let result = try await provider.pollUntilComplete(jobId: "job-123")

        XCTAssertEqual(result.provider, "assemblyai")
        XCTAssertEqual(result.utterances.count, 2)
        XCTAssertEqual(result.utterances.first?.speakerLabel, "A")
        XCTAssertEqual(result.utterances.first?.text, "Halo semua")
    }

    func testPollUntilCompleteVendorErrorThrowsVendor() async throws {
        MockURLProtocol.requestHandler = { _ in
            let body = #"{"status":"error","error":"audio tidak valid"}"#
            return (200, Data(body.utf8))
        }

        let provider = makeProvider()
        do {
            _ = try await provider.pollUntilComplete(jobId: "job-123")
            XCTFail("Harus melempar vendor error")
        } catch TranscriptionError.vendor(let message) {
            XCTAssertEqual(message, "audio tidak valid")
        }
    }

    func test401ResponseThrowsInvalidAPIKey() async throws {
        MockURLProtocol.requestHandler = { _ in
            (401, Data(#"{"error":"invalid api key"}"#.utf8))
        }

        let provider = makeProvider()
        do {
            _ = try await provider.submit(audioFileURL: try tempAudioFile(), options: TranscriptionOptions())
            XCTFail("Harus melempar invalidAPIKey")
        } catch TranscriptionError.invalidAPIKey {
            // sesuai harapan
        }
    }
}

/// `URLProtocol` tiruan supaya tes tidak melakukan request jaringan sungguhan.
final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (statusCode, data) = try handler(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
