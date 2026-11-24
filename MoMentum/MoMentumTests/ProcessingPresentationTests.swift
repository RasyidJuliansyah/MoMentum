import XCTest
@testable import MoMentum

final class ProcessingPresentationTests: XCTestCase {

    private func states(_ content: ProcessingContent) -> [ProcessingContent.StepState] {
        content.steps.map(\.state)
    }

    func testFiveStepsInHandoffOrder() {
        let content = ProcessingContent(title: "A", meta: "", status: .processing)
        XCTAssertEqual(content.steps.map(\.title), [
            "Rekaman tersimpan",
            "Segmen terunggah",
            "Transkripsi & pemisahan speaker",
            "Penyamaan label speaker",
            "Ringkasan, action items & MoM",
        ])
    }

    func testCurrentStepMarksEarlierDone() {
        let content = ProcessingContent(title: "A", meta: "", status: .processing, currentStepIndex: 2, progress: 0.62)
        XCTAssertEqual(states(content), [.done, .done, .current, .pending, .pending])
        XCTAssertEqual(content.percentText, "62%")
    }

    func testFailedStepIsMarkedFailed() {
        let content = ProcessingContent(title: "A", meta: "", status: .failed, currentStepIndex: 1)
        XCTAssertEqual(states(content), [.done, .failed, .pending, .pending, .pending])
        XCTAssertTrue(content.isFailed)
    }

    func testUnknownStepOnlyMarksRecordingSaved() {
        let content = ProcessingContent(title: "A", meta: "", status: .processing)
        XCTAssertEqual(states(content), [.done, .pending, .pending, .pending, .pending])
        XCTAssertNil(content.progress)
        XCTAssertNil(content.percentText)
    }

    func testDoneMeansAllStepsDoneAndFullProgress() {
        let content = ProcessingContent(title: "A", meta: "", status: .done, currentStepIndex: 1, progress: 0.2)
        XCTAssertEqual(states(content), Array(repeating: .done, count: 5))
        XCTAssertEqual(content.progress, 1)
    }
}
