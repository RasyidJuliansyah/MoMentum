import SwiftData
import XCTest
@testable import MoMentum

@MainActor
final class ProcessingPresentationTests: XCTestCase {

    private func states(_ content: ProcessingContent) -> [ProcessingContent.StepState] {
        content.steps.map(\.state)
    }

    // MARK: Langkah proses (layar 05)

    func testFiveStepsInFigmaOrder() {
        let content = ProcessingContent(title: "A", meta: "", status: .processing)
        XCTAssertEqual(content.steps.map(\.title), [
            "Rekaman tersimpan",
            "Segmen terunggah",
            "Transkripsi & pemisahan speaker",
            "Menyamakan label speaker antarsegmen",
            "Ringkasan, action items & MoM",
        ])
    }

    func testCurrentStepMarksEarlierDone() {
        let content = ProcessingContent(title: "A", meta: "", status: .processing, currentStepIndex: 2, progress: 0.62)
        XCTAssertEqual(states(content), [.done, .done, .current, .pending, .pending])
        XCTAssertEqual(content.percentText, "62%")
        XCTAssertEqual(content.stepCounterText, "Langkah 3 dari 5")
        XCTAssertEqual(content.steps[2].subtitle, "Bahasa Indonesia · diarization aktif")
    }

    func testFailedStepIsMarkedFailed() {
        let content = ProcessingContent(title: "A", meta: "", status: .failed, currentStepIndex: 1)
        XCTAssertEqual(states(content), [.done, .failed, .pending, .pending, .pending])
        XCTAssertTrue(content.isFailed)
    }

    func testUnknownStepOnlyMarksRecordingSaved() {
        let content = ProcessingContent(title: "A", meta: "", status: .processing)
        XCTAssertEqual(states(content), [.done, .pending, .pending, .pending, .pending])
        XCTAssertNil(content.percentText)
        XCTAssertNil(content.stepCounterText)
    }

    func testDoneMeansAllStepsDoneAndFullProgress() {
        let content = ProcessingContent(title: "A", meta: "", status: .done, currentStepIndex: 1, progress: 0.2)
        XCTAssertEqual(states(content), Array(repeating: .done, count: 5))
        XCTAssertEqual(content.progress, 1)
    }

    // MARK: Segmen dan catatan coba lagi (layar 13)

    func testRetryNoteNamesRemainingSegments() {
        XCTAssertEqual(
            ProcessingContent.previewFailed.retryNote,
            "Rekaman tetap aman di iPhone. Coba lagi hanya mengirim segmen 7–11."
        )
        let lastOnly = ProcessingContent(title: "A", meta: "", status: .failed, segments: [.done, .done, .failed])
        XCTAssertEqual(lastOnly.retryNote, "Rekaman tetap aman di iPhone. Coba lagi hanya mengirim segmen 3.")
        let noSegments = ProcessingContent(title: "A", meta: "", status: .failed)
        XCTAssertEqual(noSegments.retryNote, "Rekaman tetap aman di iPhone. Coba lagi tidak perlu merekam ulang.")
    }

    func testFailedMeetingMarksFirstUnfinishedSegment() throws {
        let container = try ModelContainer(for: Meeting.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let meeting = Meeting(title: "Sprint Planning S24", createdAt: start, status: .failed)
        container.mainContext.insert(meeting)
        for index in 0..<5 {
            let segment = Segment(fileName: "s\(index).m4a", startedAt: start.addingTimeInterval(Double(index) * 900))
            segment.transcribed = index < 2
            meeting.segments.append(segment)
        }

        let content = ProcessingContent(meeting: meeting)

        XCTAssertEqual(content.segments, [.done, .done, .failed, .pending, .pending])
        XCTAssertEqual(content.errorTitle, "Transkripsi berhenti di segmen 3")
        XCTAssertEqual(content.count(of: .pending), 2)
        XCTAssertEqual(content.steps[0].subtitle, "5 segmen di iPhone")
    }

    func testProcessingMeetingHasNoFailedSegment() throws {
        let container = try ModelContainer(for: Meeting.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let meeting = Meeting(title: "Weekly", status: .processing)
        container.mainContext.insert(meeting)
        meeting.segments.append(Segment(fileName: "a.m4a"))

        let content = ProcessingContent(meeting: meeting)

        XCTAssertEqual(content.segments, [.pending])
        XCTAssertNil(content.errorTitle)
    }

    // MARK: Format

    func testStorageFormatUsesIndonesianDecimalComma() {
        XCTAssertEqual(MFormat.storage(1_200_000_000), "1,2 GB")
        XCTAssertEqual(MFormat.storage(412_000_000), "412 MB")
    }
}
