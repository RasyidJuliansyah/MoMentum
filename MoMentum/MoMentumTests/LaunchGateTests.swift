import AVFAudio
import XCTest
@testable import MoMentum

/// Layar izin mikrofon muncul setiap app dibuka selama izin belum diberikan.
final class LaunchGateTests: XCTestCase {
    func testMicrophoneStepShownUntilGranted() throws {
        try XCTSkipIf(UITestSupport.requestedSeed != nil, "Gate dimatikan di mode UI test")
        XCTAssertTrue(LaunchGate.needsMicrophoneStep(permission: .undetermined, skipped: false), "Belum pernah ditanya")
        XCTAssertTrue(LaunchGate.needsMicrophoneStep(permission: .denied, skipped: false), "Ditolak: tunjukkan jalan ke Pengaturan")
        XCTAssertFalse(LaunchGate.needsMicrophoneStep(permission: .denied, skipped: true), "User memilih lanjut tanpa mikrofon")
        XCTAssertFalse(LaunchGate.needsMicrophoneStep(permission: .granted, skipped: false))
    }
}
