import XCTest
import SwiftData
@testable import MoMentum

// L7, D5: hapus file audio setelah retentionDays sejak Meeting.processedAt.
final class AudioRetentionCleanerTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self, Speaker.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func writeDummyFile(named fileName: String) throws {
        let url = AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)
        try Data("dummy".utf8).write(to: url)
    }

    private func fileExists(_ fileName: String) -> Bool {
        let url = AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path)
    }

    func testExpiredAudioDeleted() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Old Meeting")
        meeting.processedAt = Calendar.current.date(byAdding: .day, value: -40, to: .now)
        let fileName = "\(UUID().uuidString).wav"
        try writeDummyFile(named: fileName)
        meeting.segments.append(Segment(fileName: fileName, index: 0))
        context.insert(meeting)

        AudioRetentionCleaner.deleteExpiredAudio(in: context, retentionDays: 30)

        XCTAssertFalse(fileExists(fileName))
    }

    func testRecentAudioKept() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Recent Meeting")
        meeting.processedAt = Calendar.current.date(byAdding: .day, value: -5, to: .now)
        let fileName = "\(UUID().uuidString).wav"
        try writeDummyFile(named: fileName)
        defer { try? FileManager.default.removeItem(at: AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)) }
        meeting.segments.append(Segment(fileName: fileName, index: 0))
        context.insert(meeting)

        AudioRetentionCleaner.deleteExpiredAudio(in: context, retentionDays: 30)

        XCTAssertTrue(fileExists(fileName))
    }

    func testZeroRetentionDaysMeansKeepForever() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Ancient Meeting")
        meeting.processedAt = Calendar.current.date(byAdding: .day, value: -400, to: .now)
        let fileName = "\(UUID().uuidString).wav"
        try writeDummyFile(named: fileName)
        defer { try? FileManager.default.removeItem(at: AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)) }
        meeting.segments.append(Segment(fileName: fileName, index: 0))
        context.insert(meeting)

        AudioRetentionCleaner.deleteExpiredAudio(in: context, retentionDays: 0)

        XCTAssertTrue(fileExists(fileName))
    }

    func testUnprocessedMeetingUntouched() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "In Progress")
        let fileName = "\(UUID().uuidString).wav"
        try writeDummyFile(named: fileName)
        defer { try? FileManager.default.removeItem(at: AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)) }
        meeting.segments.append(Segment(fileName: fileName, index: 0))
        context.insert(meeting)

        AudioRetentionCleaner.deleteExpiredAudio(in: context, retentionDays: 30)

        XCTAssertTrue(fileExists(fileName), "processedAt nil berarti belum selesai diproses, jangan dihapus")
    }
}
