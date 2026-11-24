import XCTest
@testable import MoMentum

final class SettingsPresentationTests: XCTestCase {

    // MARK: KeyMask

    func testMaskShowsLastFourOnly() {
        XCTAssertEqual(KeyMask.masked("abcdefghijklmnop3f9a"), "••••••••••••3f9a")
    }

    func testMaskKeepsSkPrefix() {
        XCTAssertEqual(KeyMask.masked("sk-ant-PALSU7c21"), "sk-ant-••••••••7c21")
    }

    func testShortKeyFullyMasked() {
        XCTAssertEqual(KeyMask.masked("abc"), "•••")
    }

    // MARK: MFormat.usd

    func testUSDFormat() {
        XCTAssertEqual(MFormat.usd(10), "$10")
        XCTAssertEqual(MFormat.usd(3.2), "$3,20")
    }

    // MARK: Retensi

    func testRetentionLabels() {
        XCTAssertEqual(SettingsView.retentionOptions.map(SettingsView.retentionLabel), ["7 hari", "30 hari", "90 hari", "Selamanya"])
    }

    // MARK: Profil instalasi

    private func profileData(expiration: String) -> Data {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict><key>ExpirationDate</key><date>\(expiration)</date><key>Name</key><string>Tes</string></dict></plist>
        """
        // Data asli diapit tanda tangan CMS; byte acak di depan dan belakang menirunya.
        return Data([0x30, 0x82, 0x01, 0xFF]) + Data(plist.utf8) + Data([0x00, 0xA0, 0x82])
    }

    func testParsesExpirationDateFromProfile() throws {
        let date = try XCTUnwrap(ProvisioningProfile.expirationDate(fromProfileData: profileData(expiration: "2026-11-28T03:00:00Z")))
        XCTAssertEqual(date, ISO8601DateFormatter().date(from: "2026-11-28T03:00:00Z"))
    }

    func testGarbageProfileHasNoDate() {
        XCTAssertNil(ProvisioningProfile.expirationDate(fromProfileData: Data("bukan profil".utf8)))
    }

    func testStatusByDaysLeft() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 24, hour: 14))!
        func day(_ d: Int) -> Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: d, hour: 10))! }

        XCTAssertEqual(ProvisioningProfile.status(expiration: day(28), now: now, calendar: calendar), .expiring(daysLeft: 4))
        XCTAssertEqual(ProvisioningProfile.status(expiration: day(23), now: now, calendar: calendar), .expired)
        XCTAssertEqual(ProvisioningProfile.status(expiration: nil, now: now, calendar: calendar), .unavailable)
        let nextYear = calendar.date(from: DateComponents(year: 2027, month: 11, day: 24))!
        XCTAssertEqual(ProvisioningProfile.status(expiration: nextYear, now: now, calendar: calendar), .valid(until: nextYear))
    }
}
