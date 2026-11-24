import XCTest

/// Layar 06–08 Detail meeting dengan data contoh in-memory (`-uiTestData sample`).
final class DetailUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDetailTabsAndRenameSheet() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES", "-uiTestData", "sample"]
        app.launch()

        app.tabBars.buttons["Riwayat"].tap()
        let review = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Review PRD Absen QR")).firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 5))
        review.tap()

        // 06 Ringkasan
        XCTAssertTrue(app.staticTexts["Lihat semua (5)"].waitForExistence(timeout: 5) || app.buttons["Lihat semua (5)"].exists)
        attach(app, "06-detail-ringkasan")

        // 07 Transkrip + ganti nama
        app.buttons["Transkrip"].tap()
        let unnamed = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Speaker 4")).firstMatch
        XCTAssertTrue(unnamed.waitForExistence(timeout: 5))
        unnamed.tap()
        XCTAssertTrue(app.staticTexts["Ganti nama Speaker 4"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Simpan nama"].isEnabled, "Simpan nonaktif selama nama kosong")
        attach(app, "07-ganti-nama")
        app.buttons["Batal"].tap()

        // 08 MoM
        app.buttons["MoM"].tap()
        XCTAssertTrue(app.staticTexts["MINUTES OF MEETING"].waitForExistence(timeout: 5))
        attach(app, "08-mom")
        app.buttons["Markdown"].tap()
        attach(app, "08-mom-markdown")

        // Ekspor jadi file PDF lewat share sheet.
        app.buttons["Ekspor MoM"].tap()
        XCTAssertTrue(app.buttons["PDF"].waitForExistence(timeout: 3))
        attach(app, "08-ekspor-menu")
        app.buttons["PDF"].tap()
        sleep(2)
        XCTAssertFalse(app.alerts["File MoM gagal dibuat"].exists, "PDF harus berhasil dibuat")
        attach(app, "08-ekspor-share-sheet")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
