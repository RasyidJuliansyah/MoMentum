import XCTest

/// Alur rekam dari Beranda: rekam → tandai → jeda → stop → sheet simpan → batal → stop → simpan.
/// Rekaman masih memakai `RecordingDemoDriver` (tanpa mikrofon), jadi tes ini aman di simulator.
final class RecordingFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRecordStopSaveFlow() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES", "-userName", "Rasyid"]
        app.launch()

        attach(app, "01-beranda")

        app.buttons["Mulai merekam"].tap()
        let stopButton = app.buttons["Stop"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 5))
        sleep(2)

        app.buttons["Tandai"].tap()
        sleep(1)
        attach(app, "02-merekam")

        app.buttons["Jeda"].tap()
        XCTAssertTrue(app.buttons["Lanjut"].waitForExistence(timeout: 2))
        attach(app, "02-dijeda")

        stopButton.tap()
        XCTAssertTrue(app.staticTexts["Simpan rekaman"].waitForExistence(timeout: 5))
        attach(app, "03-simpan-rekaman")

        app.buttons["Batal"].tap()
        XCTAssertTrue(app.buttons["Lanjut"].waitForExistence(timeout: 5), "Batal harus kembali ke layar rekam dalam keadaan dijeda")

        stopButton.tap()
        XCTAssertTrue(app.buttons["Simpan & proses"].waitForExistence(timeout: 5))
        app.buttons["Simpan & proses"].tap()

        XCTAssertTrue(app.staticTexts["Ketuk untuk mulai merekam"].waitForExistence(timeout: 5), "Setelah simpan, kembali ke Beranda")
    }

    @MainActor
    func testContextFromHomeIsUsedInRecording() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES"]
        app.launch()

        app.buttons["Isi judul, agenda & istilah dulu"].tap()
        let titleField = app.textFields["Judul meeting"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Weekly Sync Product")
        attach(app, "konteks-meeting")
        app.buttons["Simpan"].tap()

        XCTAssertTrue(app.buttons["Weekly Sync Product"].waitForExistence(timeout: 5))
        app.buttons["Mulai merekam"].tap()
        XCTAssertTrue(app.staticTexts["Weekly Sync Product"].waitForExistence(timeout: 5))
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
