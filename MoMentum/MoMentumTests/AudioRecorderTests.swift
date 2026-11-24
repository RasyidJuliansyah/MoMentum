import XCTest
import SwiftData
@testable import MoMentum

// L2.2: AudioRecorder — transisi state, pergantian segmen durasi pendek, penanda di waktu audio.
final class AudioRecorderTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self, Speaker.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    func testStateTransitionsIdleRecordingPausedFinished() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60)

        XCTAssertEqual(recorder.state, .idle)

        recorder.start(title: "Daily Standup", agenda: nil, glossaryTerms: [])
        XCTAssertEqual(recorder.state, .recording)
        XCTAssertNotNil(recorder.meeting)
        XCTAssertNil(recorder.meeting?.endedAt, "endedAt nil selama rekaman belum ditutup")

        recorder.pause(reason: .phoneCall)
        XCTAssertEqual(recorder.state, .paused(.phoneCall))

        recorder.resume()
        XCTAssertEqual(recorder.state, .recording)

        recorder.stop()
        XCTAssertEqual(recorder.state, .finished)
        XCTAssertNotNil(recorder.meeting?.endedAt)
    }

    func testMarkOnlyRecordsWhileRecording() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60)

        recorder.mark() // state masih idle, diabaikan
        XCTAssertEqual(recorder.markers, [])

        recorder.start(title: "Retro", agenda: nil, glossaryTerms: [])
        recorder.mark()
        XCTAssertEqual(recorder.markers.count, 1)
        XCTAssertEqual(recorder.meeting?.markerOffsets, recorder.markers, "penanda tersinkron ke Meeting dalam waktu audio")

        recorder.pause()
        recorder.mark() // dijeda, diabaikan
        XCTAssertEqual(recorder.markers.count, 1)
    }

    func testSegmentAdvancesAfterShortDuration() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 0.5)

        recorder.start(title: "Sprint Planning", agenda: nil, glossaryTerms: [])
        XCTAssertEqual(recorder.segmentNumber, 1)
        XCTAssertEqual(recorder.meeting?.segments.count, 1)

        let expectation = expectation(description: "pergantian segmen")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertGreaterThanOrEqual(recorder.segmentNumber, 2, "segmen bertambah setelah durasi pendek terlampaui")
        XCTAssertGreaterThanOrEqual(recorder.meeting?.segments.count ?? 0, 2)

        recorder.stop()
        let indices = recorder.meeting?.segments.sorted(by: { $0.index < $1.index }).map(\.index) ?? []
        XCTAssertEqual(indices, Array(0..<indices.count), "index segmen berurutan dari 0")
    }

    func testStopFromPausedFinishesRecording() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60)

        recorder.start(title: "Weekly Sync", agenda: nil, glossaryTerms: [])
        recorder.pause()
        recorder.stop()

        XCTAssertEqual(recorder.state, .finished)
        XCTAssertNotNil(recorder.meeting?.endedAt)
    }
}
