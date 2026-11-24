import XCTest
import SwiftData
@testable import MoMentum

// L2.4: isStorageLow — ambang sisa ruang < perkiraan 1 jam rekaman (AAC mono 64kbps).
final class AudioRecorderStorageTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self, Speaker.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    func testAbundantStorageIsNotLow() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60) { 10_000_000_000 } // 10GB
        recorder.start(title: "Daily Standup", agenda: nil, glossaryTerms: [])

        XCTAssertFalse(recorder.isStorageLow)
        XCTAssertEqual(recorder.storageRemainingBytes, 10_000_000_000)
    }

    func testBelowOneHourThresholdIsLow() throws {
        let context = try makeInMemoryContext()
        let bytesPerHour = Int64(RecordingConstants.audioBitRateBps / 8) * 3600 // 28_800_000
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60) { bytesPerHour - 1 }
        recorder.start(title: "Sprint Planning", agenda: nil, glossaryTerms: [])

        XCTAssertTrue(recorder.isStorageLow)
    }

    func testExactlyAtThresholdIsNotLow() throws {
        let context = try makeInMemoryContext()
        let bytesPerHour = Int64(RecordingConstants.audioBitRateBps / 8) * 3600
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60) { bytesPerHour }
        recorder.start(title: "Retro", agenda: nil, glossaryTerms: [])

        XCTAssertFalse(recorder.isStorageLow, "tepat di ambang masih dianggap cukup")
    }

    func testFailedCapacityReadIsNotTreatedAsLow() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60) { nil }
        recorder.start(title: "Weekly Sync", agenda: nil, glossaryTerms: [])

        XCTAssertFalse(recorder.isStorageLow, "gagal baca disk tidak dianggap low, tidak ada dasar")
        XCTAssertNil(recorder.storageRemainingBytes)
        XCTAssertNil(recorder.storageRemainingHours)
    }

    func testStorageRemainingHoursComputedFromBitRate() throws {
        let context = try makeInMemoryContext()
        let bytesPerHour = Int64(RecordingConstants.audioBitRateBps / 8) * 3600
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60) { bytesPerHour * 5 }
        recorder.start(title: "Daily Standup", agenda: nil, glossaryTerms: [])

        XCTAssertEqual(recorder.storageRemainingHours, 5)
    }
}
