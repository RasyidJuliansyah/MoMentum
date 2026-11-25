import XCTest
@testable import MoMentum

final class RecordingPresentationTests: XCTestCase {

    // MARK: MFormat.clock / spokenDuration

    func testClockFormat() {
        XCTAssertEqual(MFormat.clock(4368), "01:12:48")
        XCTAssertEqual(MFormat.clock(0), "00:00:00")
        XCTAssertEqual(MFormat.clock(59.9), "00:00:59")
        XCTAssertEqual(MFormat.clock(-3), "00:00:00")
    }

    func testSpokenDuration() {
        XCTAssertEqual(MFormat.spokenDuration(4368), "1 jam 12 menit 48 detik")
        XCTAssertEqual(MFormat.spokenDuration(120), "2 menit")
        XCTAssertEqual(MFormat.spokenDuration(0), "0 detik")
    }

    // MARK: MeetingContextDraft

    func testAddTermTrimsAndRejectsDuplicates() {
        var draft = MeetingContextDraft()
        XCTAssertTrue(draft.addTerm("  SNBP "))
        XCTAssertFalse(draft.addTerm("snbp"))
        XCTAssertFalse(draft.addTerm("   "))
        XCTAssertTrue(draft.addTerm("TKA"))
        XCTAssertEqual(draft.terms, ["SNBP", "TKA"])
    }

    func testRemoveTerm() {
        var draft = MeetingContextDraft(terms: ["SNBP", "TKA"])
        draft.removeTerm("SNBP")
        XCTAssertEqual(draft.terms, ["TKA"])
    }

    func testResolvedTitleUsesInputWhenFilled() {
        let draft = MeetingContextDraft(title: "  Weekly Sync  ")
        XCTAssertEqual(draft.resolvedTitle(), "Weekly Sync")
    }

    func testResolvedTitleFallsBackToDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 24, hour: 14, minute: 20))!
        let title = MeetingContextDraft(title: "   ").resolvedTitle(at: date)
        XCTAssertTrue(title.hasPrefix("Meeting "), title)
        XCTAssertTrue(title.contains("24"), title)
    }

    func testTrimmedAgendaIsNilWhenBlank() {
        XCTAssertNil(MeetingContextDraft(agenda: "  ").trimmedAgenda)
        XCTAssertEqual(MeetingContextDraft(agenda: " Review sprint ").trimmedAgenda, "Review sprint")
    }

    // MARK: Peringatan mikrofon hening

    func testSilentInputWarningAfterThreeSecondsOfDigitalSilence() {
        var snapshot = RecordingSnapshot(title: "Tes", agenda: nil)
        snapshot.levels = Array(repeating: 0, count: 14)
        XCTAssertFalse(snapshot.isInputSilent, "Belum 3 detik")

        snapshot.levels = Array(repeating: 0, count: 15)
        XCTAssertTrue(snapshot.isInputSilent, "3 detik hening total (iPhone Mirroring / terkunci)")

        snapshot.levels = Array(repeating: 0, count: 14) + [0.17]
        XCTAssertFalse(snapshot.isInputSilent, "Ruangan sepi (-50 dB) bukan hening digital")

        snapshot.levels = Array(repeating: 0, count: 15)
        snapshot.phase = .paused(.user)
        XCTAssertFalse(snapshot.isInputSilent, "Saat dijeda tidak perlu peringatan")
    }
}
