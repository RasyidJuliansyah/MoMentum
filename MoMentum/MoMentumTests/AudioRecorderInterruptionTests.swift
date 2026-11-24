import XCTest
import SwiftData
import AVFoundation
@testable import MoMentum

// L2.3: gangguan — interupsi telepon (began/ended + shouldResume), media services reset.
// Rute audio sengaja tidak diuji state-nya (lihat komentar handleRouteChange di AudioRecorder).
final class AudioRecorderInterruptionTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Meeting.self, Segment.self, Utterance.self, ActionItem.self, Speaker.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func postInterruption(type: AVAudioSession.InterruptionType, options: AVAudioSession.InterruptionOptions = []) {
        var userInfo: [AnyHashable: Any] = [AVAudioSessionInterruptionTypeKey: type.rawValue]
        if type == .ended {
            userInfo[AVAudioSessionInterruptionOptionKey] = options.rawValue
        }
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification, object: nil, userInfo: userInfo
        )
    }

    func testInterruptionBeganPausesWithPhoneCallReason() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60)
        recorder.start(title: "Daily Standup", agenda: nil, glossaryTerms: [])
        XCTAssertEqual(recorder.state, .recording)

        postInterruption(type: .began)
        XCTAssertEqual(recorder.state, .paused(.phoneCall))
    }

    func testInterruptionEndedWithShouldResumeContinuesAutomatically() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60)
        recorder.start(title: "Sprint Planning", agenda: nil, glossaryTerms: [])

        postInterruption(type: .began)
        XCTAssertEqual(recorder.state, .paused(.phoneCall))

        postInterruption(type: .ended, options: .shouldResume)
        XCTAssertEqual(recorder.state, .recording, "shouldResume berarti lanjut otomatis")
    }

    func testInterruptionEndedWithoutShouldResumeStaysPaused() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60)
        recorder.start(title: "Retro", agenda: nil, glossaryTerms: [])

        postInterruption(type: .began)
        postInterruption(type: .ended, options: [])
        XCTAssertEqual(recorder.state, .paused(.phoneCall), "tanpa shouldResume tetap dijeda, menunggu tombol Lanjut")
    }

    func testInterruptionIgnoredWhenNotRecording() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60)
        // state masih idle
        postInterruption(type: .began)
        XCTAssertEqual(recorder.state, .idle, "interupsi saat idle diabaikan")
    }

    func testMediaServicesResetPausesRecording() throws {
        let context = try makeInMemoryContext()
        let recorder = AudioRecorder(modelContext: context, segmentDuration: 60)
        recorder.start(title: "Weekly Sync", agenda: nil, glossaryTerms: [])
        XCTAssertEqual(recorder.state, .recording)

        NotificationCenter.default.post(name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
        XCTAssertEqual(recorder.state, .paused(.phoneCall))
    }
}
