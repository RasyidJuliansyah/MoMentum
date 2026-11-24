import Foundation
import Observation

/// SEMENTARA: menyimulasikan perekam supaya layar Merekam bisa dicoba sebelum `AudioRecorder`
/// (sesi Logic, PLAN-logic.md L2) tersedia. Tidak merekam suara dan tidak menyimpan apa pun.
/// Hapus file ini setelah `RecordingView` tersambung ke `AudioRecorder`.
@Observable
final class RecordingDemoDriver {
    private(set) var snapshot: RecordingSnapshot
    private var ticker: Task<Void, Never>?

    init(title: String, agenda: String?) {
        snapshot = RecordingSnapshot(title: title, agenda: agenda)
    }

    func start() {
        guard ticker == nil else { return }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                self?.tick(seconds: 0.2)
            }
        }
    }

    func finish() {
        ticker?.cancel()
        ticker = nil
    }

    func mark() {
        guard snapshot.isRecording else { return }
        snapshot.markers.append(snapshot.elapsed)
    }

    func togglePause() {
        snapshot.phase = snapshot.isRecording ? .paused(.user) : .recording
    }

    func pause() {
        if snapshot.isRecording { snapshot.phase = .paused(.user) }
    }

    private func tick(seconds: TimeInterval) {
        guard snapshot.isRecording else { return }
        snapshot.elapsed += seconds
        snapshot.segmentNumber = Int(snapshot.elapsed / RecordingConstants.segmentDuration) + 1
        snapshot.levels.append(Double.random(in: 0.15...1))
        if snapshot.levels.count > 120 {
            snapshot.levels.removeFirst(snapshot.levels.count - 120)
        }
    }
}
