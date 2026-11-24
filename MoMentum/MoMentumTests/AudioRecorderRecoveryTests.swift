import XCTest
import SwiftData
import AVFoundation
@testable import MoMentum

// L2.5: pemulihan Meeting yang endedAt == nil (app dibunuh saat merekam).
final class AudioRecorderRecoveryTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self, Speaker.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    /// File WAV PCM valid ditulis manual (bukan lewat `AVAudioRecorder` — merekam sungguhan
    /// di simulator headless menghasilkan file kosong/tidak terbuka, lihat catatan PLAN-logic L2.3).
    /// `AVAudioPlayer` bisa membaca WAV, cukup untuk uji validasi file di `recoverUnfinishedMeetings`.
    private func writeValidSegmentFile(named fileName: String) throws {
        let url = AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)
        let sampleRate: UInt32 = 8_000
        let durationSeconds: UInt32 = 1
        let sampleCount = sampleRate * durationSeconds
        let dataSize = sampleCount * 2 // 16-bit mono
        var header = Data()
        header.append(contentsOf: Array("RIFF".utf8))
        header.append(contentsOf: withUnsafeBytes(of: UInt32(36 + dataSize).littleEndian, Array.init))
        header.append(contentsOf: Array("WAVE".utf8))
        header.append(contentsOf: Array("fmt ".utf8))
        header.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init)) // PCM
        header.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init)) // mono
        header.append(contentsOf: withUnsafeBytes(of: sampleRate.littleEndian, Array.init))
        header.append(contentsOf: withUnsafeBytes(of: (sampleRate * 2).littleEndian, Array.init)) // byte rate
        header.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian, Array.init)) // block align
        header.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian, Array.init)) // bits per sample
        header.append(contentsOf: Array("data".utf8))
        header.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian, Array.init))
        header.append(Data(repeating: 0, count: Int(dataSize))) // hening
        try header.write(to: url)
    }

    private func writeCorruptSegmentFile(named fileName: String) throws {
        let url = AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)
        try Data("bukan audio valid".utf8).write(to: url)
    }

    private func removeSegmentFile(named fileName: String) {
        let url = AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }

    func testValidSegmentsKeptAndMeetingClosed() throws {
        let context = try makeInMemoryContext()
        let fileName = "\(UUID().uuidString)-seg1.wav"
        try writeValidSegmentFile(named: fileName)
        defer { removeSegmentFile(named: fileName) }

        let meeting = Meeting(title: "Daily Standup")
        let segment = Segment(fileName: fileName, index: 0)
        meeting.segments.append(segment)
        context.insert(meeting)
        XCTAssertNil(meeting.endedAt)

        AudioRecorder.recoverUnfinishedMeetings(in: context)

        XCTAssertNotNil(meeting.endedAt, "meeting ditutup setelah pemulihan")
        XCTAssertEqual(meeting.status, .recorded)
        XCTAssertEqual(meeting.segments.count, 1, "segmen valid dipertahankan")
        XCTAssertGreaterThan(meeting.durationSeconds, 0)
    }

    func testCorruptSegmentDiscardedFileRemoved() throws {
        let context = try makeInMemoryContext()
        let fileName = "\(UUID().uuidString)-seg1.m4a"
        try writeCorruptSegmentFile(named: fileName)

        let meeting = Meeting(title: "Retro")
        let segment = Segment(fileName: fileName, index: 0)
        meeting.segments.append(segment)
        context.insert(meeting)

        AudioRecorder.recoverUnfinishedMeetings(in: context)

        XCTAssertEqual(meeting.segments.count, 0, "segmen rusak dibuang dari model")
        let url = AudioRecorder.segmentsDirectory().appendingPathComponent(fileName)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path), "file rusak dihapus dari disk")
        XCTAssertNotNil(meeting.endedAt)
        XCTAssertEqual(meeting.status, .recorded)
    }

    func testMissingSegmentFileDiscarded() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Weekly Sync")
        let segment = Segment(fileName: "\(UUID().uuidString)-seg1.m4a", index: 0) // file tidak pernah ditulis
        meeting.segments.append(segment)
        context.insert(meeting)

        AudioRecorder.recoverUnfinishedMeetings(in: context)

        XCTAssertEqual(meeting.segments.count, 0)
        XCTAssertNotNil(meeting.endedAt)
    }

    func testAlreadyFinishedMeetingUntouched() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Sprint Planning")
        meeting.endedAt = .now
        meeting.status = .done
        context.insert(meeting)
        let originalEndedAt = meeting.endedAt

        AudioRecorder.recoverUnfinishedMeetings(in: context)

        XCTAssertEqual(meeting.endedAt, originalEndedAt, "meeting yang sudah ditutup tidak diubah")
        XCTAssertEqual(meeting.status, .done)
    }

    func testRecoveryRunsAutomaticallyOnInit() throws {
        let context = try makeInMemoryContext()
        let fileName = "\(UUID().uuidString)-seg1.m4a"
        try writeCorruptSegmentFile(named: fileName)
        defer { removeSegmentFile(named: fileName) }

        let meeting = Meeting(title: "Daily Standup")
        let segment = Segment(fileName: fileName, index: 0)
        meeting.segments.append(segment)
        context.insert(meeting)

        _ = AudioRecorder(modelContext: context) // init memicu recoverUnfinishedMeetings

        XCTAssertNotNil(meeting.endedAt, "pemulihan jalan otomatis saat AudioRecorder dibuat")
    }
}
