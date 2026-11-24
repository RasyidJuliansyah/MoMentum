import XCTest
import SwiftData
@testable import MoMentum

// L4.2: normalisasi label vendor (A/B) -> "Speaker 1"/"Speaker 2" sesuai urutan kemunculan.
final class SpeakerLabelNormalizerTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self, Speaker.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    func testLabelsNormalizedByFirstAppearanceOrder() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Daily Standup")
        context.insert(meeting)

        // B muncul duluan di transkrip, jadi harus jadi "Speaker 1" walau label vendornya "B".
        let raw = [
            TranscribedUtterance(speakerLabel: "B", startMs: 0, endMs: 1000, text: "Halo"),
            TranscribedUtterance(speakerLabel: "A", startMs: 1000, endMs: 2000, text: "Pagi"),
            TranscribedUtterance(speakerLabel: "B", startMs: 2000, endMs: 3000, text: "Lanjut ya"),
        ]

        let normalized = SpeakerLabelNormalizer.normalize(raw, meeting: meeting, context: context)

        XCTAssertEqual(normalized.map(\.speakerLabel), ["Speaker 1", "Speaker 2", "Speaker 1"])
        XCTAssertEqual(normalized.map(\.text), ["Halo", "Pagi", "Lanjut ya"], "teks tidak berubah")
    }

    func testCreatesOneSpeakerPerUniqueLabel() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Retro")
        context.insert(meeting)

        let raw = [
            TranscribedUtterance(speakerLabel: "A", startMs: 0, endMs: 1000, text: "satu"),
            TranscribedUtterance(speakerLabel: "A", startMs: 1000, endMs: 2000, text: "dua"),
            TranscribedUtterance(speakerLabel: "C", startMs: 2000, endMs: 3000, text: "tiga"),
        ]

        _ = SpeakerLabelNormalizer.normalize(raw, meeting: meeting, context: context)

        XCTAssertEqual(meeting.speakers.count, 2)
        XCTAssertEqual(Set(meeting.speakers.map(\.label)), ["Speaker 1", "Speaker 2"])
    }

    func testOriginalInputUntouched() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Weekly Sync")
        context.insert(meeting)

        let raw = [TranscribedUtterance(speakerLabel: "A", startMs: 0, endMs: 1000, text: "halo")]
        _ = SpeakerLabelNormalizer.normalize(raw, meeting: meeting, context: context)

        XCTAssertEqual(raw.first?.speakerLabel, "A", "input tidak dimutasi, fungsi mengembalikan array baru")
    }

    func testEmptyUtterancesProducesNoSpeakers() throws {
        let context = try makeInMemoryContext()
        let meeting = Meeting(title: "Kickoff")
        context.insert(meeting)

        let normalized = SpeakerLabelNormalizer.normalize([], meeting: meeting, context: context)

        XCTAssertTrue(normalized.isEmpty)
        XCTAssertTrue(meeting.speakers.isEmpty)
    }
}
