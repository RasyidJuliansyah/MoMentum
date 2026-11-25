import SwiftData
import XCTest
@testable import MoMentum

@MainActor
final class HistoryPresentationTests: XCTestCase {
    private var container: ModelContainer!
    private var calendar: Calendar!
    private var now: Date!

    override func setUp() async throws {
        container = try ModelContainer(for: Meeting.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = 2 // Senin
        // Selasa 24 Nov 2026, 14.00
        now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 24, hour: 14))!
    }

    private func meeting(_ title: String, day: Int, month: Int = 11, minutes: Int = 60, status: MeetingStatus) -> Meeting {
        let date = calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 9))!
        let meeting = Meeting(title: title, createdAt: date, status: status)
        meeting.durationSeconds = TimeInterval(minutes * 60)
        container.mainContext.insert(meeting)
        return meeting
    }

    // MARK: MeetingCardContent

    func testMetaForUnfinishedMeetingShowsSegments() {
        let m = meeting("Weekly Sync Product", day: 24, minutes: 118, status: .processing)
        for index in 0..<8 {
            m.segments.append(Segment(fileName: "seg-\(index).m4a"))
        }
        XCTAssertEqual(MeetingCardContent.meta(for: m), "24 Nov · 1j 58m · 8 segmen")
    }

    func testMetaForDoneMeetingShowsActionItems() {
        let m = meeting("Review PRD", day: 21, minutes: 134, status: .done)
        m.actionItems.append(ActionItem(task: "Kirim draft", pic: "Rasyid"))
        m.actionItems.append(ActionItem(task: "Cek data", pic: "PIC belum jelas"))
        XCTAssertEqual(MeetingCardContent.meta(for: m), "21 Nov · 2j 14m · 2 action items")
    }

    func testMetaWithoutExtras() {
        let m = meeting("1:1", day: 24, minutes: 42, status: .queued)
        XCTAssertEqual(MeetingCardContent.meta(for: m), "24 Nov · 42m")
    }

    func testCardNotesPerStatus() {
        XCTAssertNil(MeetingCardContent(meeting: meeting("A", day: 24, status: .done)).note)

        let queued = MeetingCardContent(meeting: meeting("B", day: 24, status: .queued))
        XCTAssertEqual(queued.note?.text, "Diproses otomatis begitu ada internet")
        XCTAssertFalse(queued.showsRetry)

        let failed = MeetingCardContent(meeting: meeting("C", day: 24, status: .failed))
        XCTAssertTrue(failed.showsRetry)
        XCTAssertNotNil(failed.note)
    }

    func testDeleteAvailabilityPerStatus() {
        let recorded = MeetingCardContent(meeting: meeting("R", day: 24, status: .recorded))
        XCTAssertTrue(recorded.showsDelete, "Rekaman belum diproses punya tombol Hapus")
        XCTAssertFalse(recorded.showsRetry)
        XCTAssertTrue(MeetingCardContent(meeting: meeting("F", day: 24, status: .failed)).showsDelete)
        XCTAssertFalse(MeetingCardContent(meeting: meeting("D", day: 24, status: .done)).showsDelete)
        XCTAssertTrue(MeetingCardContent(meeting: meeting("D", day: 24, status: .done)).canDelete, "Selesai: hapus lewat tekan lama")
        XCTAssertFalse(MeetingCardContent(meeting: meeting("P", day: 24, status: .processing)).canDelete, "Sedang diproses tidak boleh dihapus")
    }

    func testCardShowsStepProgressAndErrorMessage() {
        let processing = meeting("D", day: 24, status: .processing)
        processing.processingStep = .uploaded
        let card = MeetingCardContent(meeting: processing, liveProgress: 0.62)
        XCTAssertEqual(card.progress?.label, "Transkripsi & pemisahan speaker · 62%")

        let failed = meeting("E", day: 24, status: .failed)
        failed.lastErrorMessage = "Ringkasan gagal (500): overloaded"
        XCTAssertEqual(MeetingCardContent(meeting: failed).note?.text, "Ringkasan gagal (500): overloaded")
    }

    // MARK: HistoryFilter

    func testFilterInProgressCoversUnfinishedStatuses() {
        XCTAssertTrue(HistoryFilter.inProgress.matches(.recorded))
        XCTAssertTrue(HistoryFilter.inProgress.matches(.queued))
        XCTAssertTrue(HistoryFilter.inProgress.matches(.processing))
        XCTAssertFalse(HistoryFilter.inProgress.matches(.done))
        XCTAssertFalse(HistoryFilter.inProgress.matches(.failed))
        XCTAssertTrue(HistoryFilter.all.matches(.failed))
    }

    // MARK: HistoryGrouping

    func testSectionsGroupByRecency() {
        let meetings = [
            meeting("Hari ini", day: 24, status: .processing),
            meeting("Senin", day: 23, status: .done),
            meeting("Awal bulan", day: 3, status: .done),
            meeting("Oktober", day: 15, month: 10, status: .failed),
        ]
        let sections = HistoryGrouping.sections(for: meetings, now: now, calendar: calendar)
        XCTAssertEqual(sections.map(\.title), ["HARI INI", "7 HARI TERAKHIR", "BULAN INI", "OKTOBER 2026"])
        XCTAssertEqual(sections.map { $0.meetings.map(\.title) }, [["Hari ini"], ["Senin"], ["Awal bulan"], ["Oktober"]])
    }

    func testSectionsApplyFilterAndQuery() {
        let meetings = [
            meeting("Weekly Sync Product", day: 24, status: .processing),
            meeting("Sprint Planning S24", day: 20, status: .failed),
            meeting("Review PRD Absen QR", day: 21, status: .done),
        ]
        let failed = HistoryGrouping.sections(for: meetings, filter: .failed, now: now, calendar: calendar)
        XCTAssertEqual(failed.flatMap(\.meetings).map(\.title), ["Sprint Planning S24"])

        let searched = HistoryGrouping.sections(for: meetings, query: "  sprint ", now: now, calendar: calendar)
        XCTAssertEqual(searched.flatMap(\.meetings).map(\.title), ["Sprint Planning S24"])

        let none = HistoryGrouping.sections(for: meetings, filter: .done, query: "weekly", now: now, calendar: calendar)
        XCTAssertTrue(none.isEmpty)
    }
}
