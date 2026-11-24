import SwiftData
import XCTest
@testable import MoMentum

@MainActor
final class DetailPresentationTests: XCTestCase {

    // MARK: Speaker

    func testSpeakersInOrderOfAppearanceWithCounts() {
        let lines = [
            TranscriptLine(id: 0, speakerLabel: "RJ", startMs: 0, text: "Oke, kita mulai."),
            TranscriptLine(id: 1, speakerLabel: "Speaker 4", startMs: 245_000, text: "IFP saja."),
            TranscriptLine(id: 2, speakerLabel: "RJ", startMs: 300_000, text: "Setuju."),
            TranscriptLine(id: 3, speakerLabel: "Bayu", startMs: 310_000, text: "Oke."),
        ]
        let speakers = MeetingDetailContent.speakers(from: lines)
        XCTAssertEqual(speakers.map(\.label), ["RJ", "Speaker 4", "Bayu"])
        XCTAssertEqual(speakers.map(\.occurrences), [2, 1, 1])
        XCTAssertEqual(speakers[2].order, 1, "Speaker tanpa nama tidak menghabiskan slot warna")
        XCTAssertEqual(speakers[1].firstStartMs, 245_000)
        XCTAssertEqual(speakers[1].firstQuote, "IFP saja.")
        XCTAssertTrue(speakers[0].isNamed)
        XCTAssertFalse(speakers[1].isNamed)
        XCTAssertEqual(speakers[0].avatarText, "R")
        XCTAssertEqual(speakers[1].avatarText, "4")
    }

    func testDetailContentFromMeeting() throws {
        let container = try ModelContainer(for: Meeting.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let meeting = Meeting(title: "Review PRD", status: .done)
        meeting.durationSeconds = 134 * 60
        meeting.summaryText = "Paragraf satu.\n\nParagraf dua.\n\n"
        container.mainContext.insert(meeting)
        let segment = Segment(fileName: "a.m4a")
        meeting.segments.append(segment)
        segment.utterances.append(Utterance(speakerLabel: "Dina", startMs: 2000, endMs: 3000, text: "Dua"))
        segment.utterances.append(Utterance(speakerLabel: "RJ", startMs: 1000, endMs: 1900, text: "Satu"))
        meeting.actionItems.append(ActionItem(task: "Cek kebijakan", pic: "PIC belum jelas"))

        let content = MeetingDetailContent(meeting: meeting)

        XCTAssertEqual(content.summaryParagraphs, ["Paragraf satu.", "Paragraf dua."])
        XCTAssertEqual(content.transcript.map(\.text), ["Satu", "Dua"], "Urut berdasarkan waktu mulai")
        XCTAssertEqual(content.participantCount, 2)
        XCTAssertEqual(content.durationText, "2j 14m")
        XCTAssertNil(content.actionItems.first?.pic, "\"PIC belum jelas\" dianggap tanpa PIC")
    }

    // MARK: MoM

    private var document: MoMDocument {
        MoMDocument(
            title: "Review PRD Absen QR",
            dateText: "21 Nov 2026",
            timeText: "09.00–11.14 WIB",
            participants: ["RJ", "Dina", "Bayu", "Pak Hendra", "Sari", "Tim Data"],
            topics: ["Mekanisme QR dinamis"],
            decisions: ["Validasi lokasi ditunda ke fase 2"],
            actionItems: [
                ActionItemContent(task: "Generator QR dinamis", pic: "Bayu", due: "28 Nov"),
                ActionItemContent(task: "Cek kebijakan HP", pic: nil, due: nil),
            ]
        )
    }

    func testParticipantsTextTruncatesAfterFour() {
        XCTAssertEqual(document.participantsText, "RJ, Dina, Bayu, Pak Hendra, +2")
    }

    func testTimeRangeUsesIndonesianZoneName() {
        let jakarta = TimeZone(identifier: "Asia/Jakarta")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = jakarta
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 21, hour: 9))!
        XCTAssertEqual(MoMDocument.timeRange(start: start, duration: 134 * 60, timeZone: jakarta), "09.00–11.14 WIB")
        XCTAssertEqual(MoMDocument.zoneName(TimeZone(identifier: "Asia/Makassar")!, at: start), "WITA")
    }

    func testMarkdownExport() {
        let markdown = document.markdown()
        XCTAssertTrue(markdown.hasPrefix("# MoM: Review PRD Absen QR"))
        XCTAssertTrue(markdown.contains("## Topik\n1. Mekanisme QR dinamis"))
        XCTAssertTrue(markdown.contains("## Keputusan\n- Validasi lokasi ditunda ke fase 2"))
        XCTAssertTrue(markdown.contains("- [ ] Generator QR dinamis — Bayu · 28 Nov"))
        XCTAssertTrue(markdown.contains("- [ ] Cek kebijakan HP — PIC belum jelas"))
    }

    func testPlainTextSkipsEmptySections() {
        var empty = document
        empty.topics = []
        empty.decisions = []
        let text = empty.plainText()
        XCTAssertTrue(text.hasPrefix("MINUTES OF MEETING\nReview PRD Absen QR"))
        XCTAssertFalse(text.contains("Topik"))
        XCTAssertFalse(text.contains("Keputusan"))
        XCTAssertTrue(text.contains("• Generator QR dinamis — Bayu · 28 Nov"))
    }
}
