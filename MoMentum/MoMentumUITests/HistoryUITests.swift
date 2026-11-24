import XCTest

/// Layar Riwayat dengan database in-memory (`-uiTestData`), jadi data asli tidak tersentuh.
final class HistoryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEmptyHistoryStartsRecording() throws {
        let app = launch(seed: "empty")
        app.tabBars.buttons["Riwayat"].tap()

        XCTAssertTrue(app.staticTexts["Belum ada meeting"].waitForExistence(timeout: 5))
        attach(app, "12-riwayat-kosong")

        app.buttons["Mulai rekam"].tap()
        XCTAssertTrue(app.buttons["Stop"].waitForExistence(timeout: 5), "Tombol di state kosong harus membuka layar rekam")
    }

    @MainActor
    func testHistoryListFilterAndOpenMeeting() throws {
        let app = launch(seed: "sample")
        app.tabBars.buttons["Riwayat"].tap()

        let weekly = card(app, "Weekly Sync Product")
        XCTAssertTrue(weekly.waitForExistence(timeout: 5))
        attach(app, "04-riwayat")

        app.buttons["Gagal"].tap()
        let sprint = card(app, "Sprint Planning S24")
        XCTAssertTrue(sprint.waitForExistence(timeout: 2))
        XCTAssertFalse(card(app, "Weekly Sync Product").exists, "Filter Gagal hanya menampilkan meeting gagal")
        attach(app, "04-riwayat-gagal")

        sprint.tap()
        XCTAssertTrue(element(app, startingWith: "Transkripsi berhenti di segmen 7").waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, startingWith: "Status segmen: 6 selesai, 1 gagal, 4 menunggu").exists)
        attach(app, "13-proses-gagal")

        app.buttons["Cek API key"].tap()
        XCTAssertTrue(app.tabBars.buttons["Pengaturan"].isSelected, "Cek API key harus pindah ke tab Pengaturan")
    }

    @MainActor
    func testProcessingMeetingOpensProcessingScreen() throws {
        let app = launch(seed: "sample")
        app.tabBars.buttons["Riwayat"].tap()

        let weekly = card(app, "Weekly Sync Product")
        XCTAssertTrue(weekly.waitForExistence(timeout: 5))
        weekly.tap()

        XCTAssertTrue(element(app, startingWith: "Ringkasan, action items & MoM").waitForExistence(timeout: 5))
        XCTAssertTrue(element(app, startingWith: "Biarkan app terbuka").exists)
        attach(app, "05-memproses")
    }

    @MainActor
    private func element(_ app: XCUIApplication, startingWith text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
    }

    @MainActor
    private func launch(seed: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES", "-uiTestData", seed]
        app.launch()
        return app
    }

    @MainActor
    private func card(_ app: XCUIApplication, _ title: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
