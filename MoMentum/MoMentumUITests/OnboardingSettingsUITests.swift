import XCTest

/// Alur onboarding (10 → 11 → TabView) dan layar Pengaturan (09).
final class OnboardingSettingsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingSkipKeyThenMicrophone() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestData", "empty", "-uiTestResetDefaults"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Pasang API key dulu"].waitForExistence(timeout: 5))
        attach(app, "10-onboarding-key")
        app.buttons["Nanti saja"].tap()

        XCTAssertTrue(app.staticTexts["Izinkan akses mikrofon"].waitForExistence(timeout: 5))
        attach(app, "11-onboarding-mic")

        if app.buttons["Izinkan mikrofon"].exists {
            app.buttons["Izinkan mikrofon"].tap()
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let alert = springboard.alerts.firstMatch
            if alert.waitForExistence(timeout: 3) {
                let allow = alert.buttons.matching(NSPredicate(format: "label IN %@", ["Allow", "Izinkan", "OK"])).firstMatch
                (allow.exists ? allow : alert.buttons.element(boundBy: alert.buttons.count - 1)).tap()
            }
        } else {
            // Izin pernah ditolak di simulator ini.
            app.buttons["Lanjut tanpa mikrofon"].tap()
        }

        XCTAssertTrue(app.staticTexts["Ketuk untuk mulai merekam"].waitForExistence(timeout: 5), "Selesai onboarding masuk ke Beranda")
    }

    @MainActor
    func testSettingsScreen() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES", "-uiTestData", "empty"]
        app.launch()

        app.tabBars.buttons["Pengaturan"].tap()
        XCTAssertTrue(app.staticTexts["API KEY · BYOK"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Speech-to-text"].exists)
        attach(app, "09-pengaturan")
    }

    @MainActor
    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
