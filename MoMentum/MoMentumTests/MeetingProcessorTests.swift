import XCTest
import SwiftData
@testable import MoMentum

// L6.4: urutan status alur normal, gagal -> .failed dengan jenis error benar,
// coba lagi melanjutkan dari langkah gagal, offline -> .queued.
final class MeetingProcessorTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self, Speaker.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    /// File WAV PCM valid di `AudioRecorder.segmentsDirectory()` — `AudioMerger` (dipanggil
    /// `uploadStep`) butuh file sungguhan yang bisa dibaca `AVURLAsset`.
    private func writeValidSegmentFile(named fileName: String) throws {
        let url = AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)
        let sampleRate: UInt32 = 8_000
        let sampleCount = sampleRate
        let dataSize = sampleCount * 2
        var header = Data()
        header.append(contentsOf: Array("RIFF".utf8))
        header.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian, Array.init))
        header.append(contentsOf: Array("WAVE".utf8))
        header.append(contentsOf: Array("fmt ".utf8))
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: (sampleRate * 2).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian, Array.init))
        header.append(contentsOf: Array("data".utf8))
        header.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian, Array.init))
        header.append(Data(repeating: 0, count: Int(dataSize)))
        try header.write(to: url)
    }

    private func makeMeetingWithSegment(in context: ModelContext, title: String) throws -> Meeting {
        let meeting = Meeting(title: title)
        meeting.endedAt = .now
        let fileName = "\(UUID().uuidString)-seg1.wav"
        try writeValidSegmentFile(named: fileName)
        let segment = Segment(fileName: fileName, index: 0)
        meeting.segments.append(segment)
        context.insert(meeting)
        return meeting
    }

    /// Polling sederhana sampai kondisi terpenuhi atau timeout — `MeetingProcessor.process`
    /// jalan di `Task` terpisah tanpa API "tunggu selesai" eksplisit.
    private func waitUntil(timeout: TimeInterval = 3, _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Alur normal

    func testNormalFlowGoesThroughAllStepsToDone() async throws {
        let context = try makeInMemoryContext()
        let meeting = try makeMeetingWithSegment(in: context, title: "Daily Standup")

        let transcription = FakeTranscriptionProvider(submitResult: .success("job-1"), pollResult: .success(
            TranscriptResult(provider: "fake", utterances: [
                TranscribedUtterance(speakerLabel: "A", startMs: 0, endMs: 1000, text: "Halo"),
            ])
        ))
        let summary = FakeSummaryProvider(result: .success(
            SummaryResult(summaryText: "Ringkasan.", topics: ["Topik A"], decisions: ["Keputusan A"], actionItems: [
                SummaryActionItem(task: "Kerjakan X", pic: "Speaker 1", dueDate: nil),
            ])
        ))
        let processor = MeetingProcessor(
            modelContext: context, transcriptionProvider: transcription, summaryProvider: summary,
            notifier: { _, _ in }
        )

        processor.process(meeting)
        await waitUntil { meeting.status == .done }

        XCTAssertEqual(meeting.status, .done)
        XCTAssertEqual(meeting.processingStep, .summarizing)
        XCTAssertEqual(meeting.providerJobId, "job-1")
        XCTAssertEqual(meeting.summaryText, "Ringkasan.")
        XCTAssertEqual(meeting.topics, ["Topik A"])
        XCTAssertEqual(meeting.actionItems.count, 1)
        XCTAssertNotNil(meeting.processedAt)
    }

    // MARK: - D6: hapus transkrip di vendor setelah tersimpan lokal

    func testDeleteTranscriptCalledAfterSuccessfulTranscription() async throws {
        let context = try makeInMemoryContext()
        let meeting = try makeMeetingWithSegment(in: context, title: "Daily Standup")

        let transcription = FakeTranscriptionProvider(submitResult: .success("job-1"), pollResult: .success(
            TranscriptResult(provider: "fake", utterances: [TranscribedUtterance(speakerLabel: "A", startMs: 0, endMs: 500, text: "halo")])
        ))
        let summary = FakeSummaryProvider(result: .success(SummaryResult(summaryText: "", topics: [], decisions: [], actionItems: [])))
        let processor = MeetingProcessor(modelContext: context, transcriptionProvider: transcription, summaryProvider: summary, notifier: { _, _ in })

        processor.process(meeting)
        await waitUntil { meeting.status == .done }

        XCTAssertEqual(transcription.deleteCallCount, 1)
    }

    // MARK: - Gagal -> .failed dengan jenis error benar

    func testVendorErrorDuringTranscriptionMarksFailedWithVendorKind() async throws {
        let context = try makeInMemoryContext()
        let meeting = try makeMeetingWithSegment(in: context, title: "Retro")

        let transcription = FakeTranscriptionProvider(
            submitResult: .success("job-1"),
            pollResult: .failure(TranscriptionError.vendor("audio tidak valid"))
        )
        let summary = FakeSummaryProvider(result: .success(SummaryResult(summaryText: "", topics: [], decisions: [], actionItems: [])))
        let processor = MeetingProcessor(modelContext: context, transcriptionProvider: transcription, summaryProvider: summary, notifier: { _, _ in })

        processor.process(meeting)
        await waitUntil { meeting.status == .failed }

        XCTAssertEqual(meeting.status, .failed)
        XCTAssertEqual(meeting.lastErrorKind, .vendor)
        XCTAssertEqual(meeting.lastErrorMessage, "audio tidak valid")
    }

    func testInvalidAPIKeyDuringUploadMarksFailedWithInvalidAPIKeyKind() async throws {
        let context = try makeInMemoryContext()
        let meeting = try makeMeetingWithSegment(in: context, title: "Weekly Sync")

        let transcription = FakeTranscriptionProvider(submitResult: .failure(TranscriptionError.invalidAPIKey), pollResult: .success(TranscriptResult(provider: "fake", utterances: [])))
        let summary = FakeSummaryProvider(result: .success(SummaryResult(summaryText: "", topics: [], decisions: [], actionItems: [])))
        let processor = MeetingProcessor(modelContext: context, transcriptionProvider: transcription, summaryProvider: summary, notifier: { _, _ in })

        processor.process(meeting)
        await waitUntil { meeting.status == .failed }

        XCTAssertEqual(meeting.status, .failed)
        XCTAssertEqual(meeting.lastErrorKind, .invalidAPIKey)
    }

    // MARK: - Coba lagi melanjutkan dari langkah gagal

    func testRetryResumesFromFailedStepWithoutReupload() async throws {
        let context = try makeInMemoryContext()
        let meeting = try makeMeetingWithSegment(in: context, title: "Sprint Planning")

        var submitCallCount = 0
        let transcription = FakeTranscriptionProvider(
            submitResult: .success("job-1"),
            pollResult: .failure(TranscriptionError.vendor("timeout polling")),
            onSubmit: { submitCallCount += 1 }
        )
        let summary = FakeSummaryProvider(result: .success(SummaryResult(summaryText: "", topics: [], decisions: [], actionItems: [])))
        let processor = MeetingProcessor(modelContext: context, transcriptionProvider: transcription, summaryProvider: summary, notifier: { _, _ in })

        processor.process(meeting)
        await waitUntil { meeting.status == .failed }
        XCTAssertEqual(submitCallCount, 1, "submit (upload) terjadi sekali di percobaan pertama")

        transcription.pollResult = .success(TranscriptResult(provider: "fake", utterances: [
            TranscribedUtterance(speakerLabel: "A", startMs: 0, endMs: 500, text: "halo"),
        ]))
        processor.retry(meeting)
        await waitUntil { meeting.status == .done }

        XCTAssertEqual(meeting.status, .done)
        XCTAssertEqual(submitCallCount, 1, "retry tidak upload ulang karena sudah .uploaded")
    }

    // MARK: - Offline -> .queued

    func testNetworkErrorDuringUploadMarksQueued() async throws {
        let context = try makeInMemoryContext()
        let meeting = try makeMeetingWithSegment(in: context, title: "Kickoff")

        let transcription = FakeTranscriptionProvider(submitResult: .failure(TranscriptionError.network("offline")), pollResult: .success(TranscriptResult(provider: "fake", utterances: [])))
        let summary = FakeSummaryProvider(result: .success(SummaryResult(summaryText: "", topics: [], decisions: [], actionItems: [])))
        let processor = MeetingProcessor(modelContext: context, transcriptionProvider: transcription, summaryProvider: summary, notifier: { _, _ in })

        processor.process(meeting)
        await waitUntil { meeting.status == .queued }

        XCTAssertEqual(meeting.status, .queued)
        XCTAssertNil(meeting.lastErrorKind, "offline tidak dianggap error permanen")
    }
}

// MARK: - Test doubles

private final class FakeTranscriptionProvider: TranscriptionProvider {
    var submitResult: Result<String, Error>
    var pollResult: Result<TranscriptResult, Error>
    var onSubmit: (() -> Void)?

    init(submitResult: Result<String, Error>, pollResult: Result<TranscriptResult, Error>, onSubmit: (() -> Void)? = nil) {
        self.submitResult = submitResult
        self.pollResult = pollResult
        self.onSubmit = onSubmit
    }

    func submit(audioFileURL: URL, options: TranscriptionOptions) async throws -> String {
        onSubmit?()
        return try submitResult.get()
    }

    func pollUntilComplete(jobId: String) async throws -> TranscriptResult {
        try pollResult.get()
    }

    var deleteCallCount = 0
    func deleteTranscript(jobId: String) async {
        deleteCallCount += 1
    }
}

private final class FakeSummaryProvider: SummaryProvider {
    var result: Result<SummaryResult, Error>

    init(result: Result<SummaryResult, Error>) {
        self.result = result
    }

    func summarize(_ input: SummaryInput) async throws -> SummaryResult {
        try result.get()
    }
}
