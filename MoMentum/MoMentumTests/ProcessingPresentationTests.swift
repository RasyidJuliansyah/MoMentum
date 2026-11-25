import SwiftData
import XCTest
@testable import MoMentum

@MainActor
final class ProcessingPresentationTests: XCTestCase {

    private func states(_ content: ProcessingContent) -> [ProcessingContent.StepState] {
        content.steps.map(\.state)
    }

    // MARK: Langkah proses (satu file utuh, D2 = A)

    func testFourStepsInOrder() {
        let content = ProcessingContent(title: "A", meta: "", status: .processing)
        XCTAssertEqual(content.steps.map(\.title), [
            "Rekaman tersimpan",
            "Rekaman terunggah",
            "Transkripsi & pemisahan speaker",
            "Ringkasan, action items & MoM",
        ])
    }

    func testCurrentStepMarksEarlierDone() {
        let content = ProcessingContent(title: "A", meta: "", status: .processing, currentStepIndex: 2, progress: 0.62)
        XCTAssertEqual(states(content), [.done, .done, .current, .pending])
        XCTAssertEqual(content.percentText, "62%")
        XCTAssertEqual(content.stepCounterText, "Langkah 3 dari 4")
        XCTAssertEqual(content.steps[2].subtitle, "Bahasa Indonesia · diarization aktif")
    }

    func testFailedStepIsMarkedAndNamed() {
        let content = ProcessingContent(title: "A", meta: "", status: .failed, currentStepIndex: 1)
        XCTAssertEqual(states(content), [.done, .failed, .pending, .pending])
        XCTAssertEqual(content.errorTitle, "Upload rekaman gagal")
        XCTAssertTrue(content.isFailed)
    }

    func testFailedWithoutStepInfoHasGenericTitle() {
        let content = ProcessingContent(title: "A", meta: "", status: .failed)
        XCTAssertEqual(content.errorTitle, "Proses gagal")
        XCTAssertEqual(states(content), [.done, .pending, .pending, .pending])
    }

    func testUnknownStepOnlyMarksRecordingSaved() {
        let content = ProcessingContent(title: "A", meta: "", status: .processing)
        XCTAssertEqual(states(content), [.done, .pending, .pending, .pending])
        XCTAssertNil(content.percentText)
        XCTAssertNil(content.stepCounterText)
        XCTAssertNil(content.errorTitle)
    }

    func testDoneMeansAllStepsDoneAndFullProgress() {
        let content = ProcessingContent(title: "A", meta: "", status: .done, currentStepIndex: 1, progress: 0.2)
        XCTAssertEqual(states(content), Array(repeating: .done, count: 4))
        XCTAssertEqual(content.progress, 1)
    }

    func testMeetingSegmentsShowAsRecordingSubtitle() throws {
        let container = try ModelContainer(for: Meeting.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let meeting = Meeting(title: "Weekly", status: .processing)
        container.mainContext.insert(meeting)
        for index in 0..<5 {
            meeting.segments.append(Segment(fileName: "s\(index).m4a"))
        }
        XCTAssertEqual(ProcessingContent(meeting: meeting).steps[0].subtitle, "5 segmen di iPhone")
    }

    func testStepAndErrorComeFromMeeting() throws {
        let container = try ModelContainer(for: Meeting.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let meeting = Meeting(title: "Weekly", status: .processing)
        container.mainContext.insert(meeting)
        meeting.processingStep = .uploaded

        let running = ProcessingContent(meeting: meeting)
        XCTAssertEqual(running.currentStepIndex, 2, "Terunggah selesai → sedang transkripsi")
        XCTAssertEqual(running.progress, 0.5)
        XCTAssertEqual(ProcessingContent(meeting: meeting, liveProgress: 0.62).percentText, "62%")

        meeting.status = .failed
        meeting.lastErrorMessage = "API key belum diisi atau tidak valid."
        let failed = ProcessingContent(meeting: meeting)
        XCTAssertEqual(failed.errorTitle, "Transkripsi gagal")
        XCTAssertEqual(failed.errorMessage, "API key belum diisi atau tidak valid.")

        meeting.status = .recorded
        meeting.processingStep = nil
        XCTAssertNil(ProcessingContent(meeting: meeting).currentStepIndex)
    }

    // MARK: Format

    func testStorageFormatUsesIndonesianDecimalComma() {
        XCTAssertEqual(MFormat.storage(1_200_000_000), "1,2 GB")
        XCTAssertEqual(MFormat.storage(412_000_000), "412 MB")
    }
}
