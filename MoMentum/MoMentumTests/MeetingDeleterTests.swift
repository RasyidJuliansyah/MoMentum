import SwiftData
import XCTest
@testable import MoMentum

/// Hapus meeting dari Riwayat: data dan file audio di iPhone ikut hilang.
final class MeetingDeleterTests: XCTestCase {

    func testDeleteRemovesMeetingAndAudioFiles() throws {
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self, Speaker.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = ModelContext(container)

        let meeting = Meeting(title: "Gagal", status: .failed)
        let fileName = "\(UUID().uuidString)-seg1.m4a"
        let url = AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)
        try Data("audio".utf8).write(to: url)
        meeting.segments.append(Segment(fileName: fileName))
        context.insert(meeting)
        let other = Meeting(title: "Tetap", status: .done)
        context.insert(other)
        try context.save()

        MeetingDeleter.delete(meeting, in: context)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        let remaining = try context.fetch(FetchDescriptor<Meeting>())
        XCTAssertEqual(remaining.map(\.title), ["Tetap"])
        XCTAssertTrue(try context.fetch(FetchDescriptor<Segment>()).isEmpty, "Segmen ikut terhapus")
    }
}
