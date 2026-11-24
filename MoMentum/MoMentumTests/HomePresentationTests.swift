import XCTest
@testable import MoMentum

final class HomePresentationTests: XCTestCase {

    // MARK: MFormat.duration

    func testDurationUnderOneHourShowsMinutesOnly() {
        XCTAssertEqual(MFormat.duration(42 * 60), "42m")
        XCTAssertEqual(MFormat.duration(30), "0m")
    }

    func testDurationWithHoursAndMinutes() {
        XCTAssertEqual(MFormat.duration(118 * 60), "1j 58m")
        XCTAssertEqual(MFormat.duration(33_600), "9j 20m")
    }

    func testDurationWholeHoursDropsMinutes() {
        XCTAssertEqual(MFormat.duration(2 * 3600), "2j")
    }

    func testDurationNegativeIsZero() {
        XCTAssertEqual(MFormat.duration(-5), "0m")
    }

    // MARK: Greeting

    private func date(hour: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 24, hour: hour))!
    }

    func testGreetingByHour() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta")!
        XCTAssertEqual(Greeting.text(for: date(hour: 7, calendar: calendar), calendar: calendar), "Selamat pagi")
        XCTAssertEqual(Greeting.text(for: date(hour: 12, calendar: calendar), calendar: calendar), "Selamat siang")
        XCTAssertEqual(Greeting.text(for: date(hour: 16, calendar: calendar), calendar: calendar), "Selamat sore")
        XCTAssertEqual(Greeting.text(for: date(hour: 21, calendar: calendar), calendar: calendar), "Selamat malam")
        XCTAssertEqual(Greeting.text(for: date(hour: 2, calendar: calendar), calendar: calendar), "Selamat malam")
    }

    func testInitials() {
        XCTAssertEqual(Greeting.initials(of: "Rasyid Juliansyah"), "RJ")
        XCTAssertEqual(Greeting.initials(of: "rasyid"), "R")
        XCTAssertEqual(Greeting.initials(of: "Ana Budi Citra"), "AB")
        XCTAssertEqual(Greeting.initials(of: ""), "")
    }

    // MARK: WeeklyStats

    func testWeeklyStatsCountsOnlyThisWeek() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta")!
        calendar.firstWeekday = 2 // Senin
        // Selasa 24 Nov 2026
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 24, hour: 14))!
        let monday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 9))!
        let lastWeek = calendar.date(from: DateComponents(year: 2026, month: 11, day: 20, hour: 9))!

        let done = Meeting(title: "A", createdAt: monday, status: .done)
        done.durationSeconds = 3600
        let processing = Meeting(title: "B", createdAt: now, status: .processing)
        processing.durationSeconds = 1200
        let old = Meeting(title: "C", createdAt: lastWeek, status: .done)
        old.durationSeconds = 9999

        let stats = WeeklyStats(meetings: [done, processing, old], now: now, calendar: calendar)

        XCTAssertEqual(stats, WeeklyStats(meetingCount: 2, recordedSeconds: 4800, momReadyCount: 1))
    }

    func testWeeklyStatsEmpty() {
        XCTAssertEqual(WeeklyStats(meetings: []), WeeklyStats())
    }
}
