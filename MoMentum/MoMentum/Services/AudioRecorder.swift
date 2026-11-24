import Foundation
import AVFoundation
import SwiftData

/// Perekam inti (L2.2). D8 = A: `AVAudioRecorder` per segmen, AAC mono 64 kbps.
/// Tiap `RecordingConstants.segmentDuration` detik, recorder berhenti dan segmen baru
/// dimulai — ada celah mikro antar segmen (diterima, lihat PLAN-logic.md D8).
@Observable
final class AudioRecorder: NSObject {
    enum PauseReason: Equatable {
        case user
        case phoneCall
    }

    enum State: Equatable {
        case idle
        case recording
        case paused(PauseReason)
        case finished
    }

    private(set) var state: State = .idle
    /// Durasi audio yang sudah terekam (jeda tidak dihitung).
    private(set) var elapsed: TimeInterval = 0
    /// Mulai dari 1 ("Segmen 1").
    private(set) var segmentNumber: Int = 1
    /// Level 0...1, terbaru di akhir. Dipakai `WaveformView`.
    private(set) var levels: [Double] = []
    /// Penanda momen (tombol Tandai), dalam waktu audio.
    private(set) var markers: [TimeInterval] = []
    /// L2.4: sisa ruang disk kurang dari `RecordingConstants.lowStorageThresholdBytes`. Banner layar 15.
    private(set) var isStorageLow: Bool = false
    /// Sisa ruang disk dalam byte. `nil` kalau belum dicek atau gagal baca. Dipetakan ke
    /// `RecordingSnapshot.storageRemainingBytes` (kontrak UI, lihat docs/handover.md bagian 4).
    private(set) var storageRemainingBytes: Int64?
    /// Perkiraan sisa ruang dalam jam rekaman (bitrate D8). `nil` kalau `storageRemainingBytes` nil.
    var storageRemainingHours: Int? {
        guard let storageRemainingBytes else { return nil }
        let bytesPerHour = Int64(RecordingConstants.audioBitRateBps / 8) * 3600
        return Int(storageRemainingBytes / bytesPerHour)
    }

    private let modelContext: ModelContext
    private let segmentDuration: TimeInterval
    /// Byte tersisa yang "penting untuk pemakaian" (`volumeAvailableCapacityForImportantUsageKey`).
    /// Injectable supaya tes bisa memberi nilai tiruan tanpa bergantung disk simulator asli.
    private let availableCapacityProvider: () -> Int64?
    private(set) var meeting: Meeting?
    private var recorder: AVAudioRecorder?
    private var currentSegment: Segment?
    private var currentSegmentStartElapsed: TimeInterval = 0
    private var levelTimer: Timer?
    private var segmentTimer: Timer?

    /// `segmentDuration` dikirim lewat init (default `RecordingConstants.segmentDuration`)
    /// supaya tes bisa memakai durasi pendek. `availableCapacityProvider` sama alasannya untuk L2.4.
    init(
        modelContext: ModelContext,
        segmentDuration: TimeInterval = RecordingConstants.segmentDuration,
        availableCapacityProvider: @escaping () -> Int64? = AudioRecorder.systemAvailableCapacity
    ) {
        self.modelContext = modelContext
        self.segmentDuration = segmentDuration
        self.availableCapacityProvider = availableCapacityProvider
        super.init()
        registerSessionObservers()
    }

    /// Default provider: `volumeAvailableCapacityForImportantUsageKey` dari folder Documents.
    static func systemAvailableCapacity() -> Int64? {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let values = try? documents.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Aksi dipanggil UI

    func start(title: String, agenda: String?, glossaryTerms: [String]) {
        guard state == .idle else { return }
        let newMeeting = Meeting(title: title)
        newMeeting.agenda = agenda
        newMeeting.glossaryTerms = glossaryTerms
        modelContext.insert(newMeeting)
        meeting = newMeeting
        elapsed = 0
        segmentNumber = 1
        levels = []
        markers = []
        checkStorage()
        startSegment()
        state = .recording
        startTimers()
    }

    func mark() {
        guard state == .recording else { return }
        markers.append(elapsed)
        meeting?.markerOffsets = markers
    }

    func pause(reason: PauseReason = .user) {
        guard state == .recording else { return }
        stopTimers()
        finishCurrentSegment()
        state = .paused(reason)
    }

    func resume() {
        guard state.isPaused else { return }
        startSegment()
        state = .recording
        startTimers()
    }

    /// Menutup rekaman (tombol Stop → sheet Simpan di UI). `Meeting.endedAt` diisi di sini;
    /// status/proses lanjutan ditangani alur terpisah (L6, `MeetingProcessor`).
    func stop() {
        guard state == .recording || state.isPaused else { return }
        stopTimers()
        if state == .recording {
            finishCurrentSegment()
        }
        meeting?.durationSeconds = elapsed
        meeting?.endedAt = .now
        state = .finished
    }

    // MARK: - Internal

    private func startSegment() {
        guard let meeting else { return }
        let fileName = "\(UUID().uuidString)-seg\(segmentNumber).m4a"
        let url = Self.segmentsDirectory().appendingPathComponent(fileName)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: RecordingConstants.audioBitRateBps,
        ]
        let segment = Segment(fileName: fileName, index: segmentNumber - 1)
        meeting.segments.append(segment)
        currentSegment = segment
        currentSegmentStartElapsed = elapsed

        do {
            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.delegate = self
            newRecorder.isMeteringEnabled = true
            newRecorder.record()
            recorder = newRecorder
        } catch {
            recorder = nil
        }
    }

    private func finishCurrentSegment() {
        recorder?.stop()
        currentSegment?.durationSeconds = elapsed - currentSegmentStartElapsed
        recorder = nil
        currentSegment = nil
    }

    private func advanceToNextSegment() {
        finishCurrentSegment()
        segmentNumber += 1
        startSegment()
    }

    private func startTimers() {
        levelTimer?.invalidate()
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.tick()
        }
        segmentTimer?.invalidate()
        segmentTimer = Timer.scheduledTimer(withTimeInterval: segmentDuration, repeats: true) { [weak self] _ in
            self?.advanceToNextSegment()
        }
    }

    private func stopTimers() {
        levelTimer?.invalidate()
        levelTimer = nil
        segmentTimer?.invalidate()
        segmentTimer = nil
    }

    private func tick() {
        elapsed += 0.2
        recorder?.updateMeters()
        if let recorder {
            // averagePower: -60 (hening, batas praktis) ... 0 (penuh). Dipetakan ke 0...1.
            let power = recorder.averagePower(forChannel: 0)
            let normalized = max(0, min(1, (power + 60) / 60))
            levels.append(Double(normalized))
        } else {
            levels.append(0)
        }
        // Cek tiap ~5 detik (25 tick @ 0.2s), bukan tiap tick — cukup berkala, hindari syscall berlebih.
        if levels.count % 25 == 0 {
            checkStorage()
        }
    }

    /// L2.4: perbarui `isStorageLow` dari `availableCapacityProvider`. `nil` (gagal baca disk)
    /// dianggap tidak low — tidak ada info lebih baik daripada menakut-nakuti user tanpa dasar.
    private func checkStorage() {
        guard let bytes = availableCapacityProvider() else {
            isStorageLow = false
            storageRemainingBytes = nil
            return
        }
        storageRemainingBytes = bytes
        isStorageLow = bytes < RecordingConstants.lowStorageThresholdBytes
    }

    // MARK: - Gangguan (L2.3)

    private func registerSessionObservers() {
        let center = NotificationCenter.default
        center.addObserver(
            self, selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification, object: nil
        )
        center.addObserver(
            self, selector: #selector(handleMediaServicesReset(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification, object: nil
        )
    }

    /// Telepon masuk (atau gangguan sistem lain): jeda dengan alasan `.phoneCall` dan tutup
    /// segmen berjalan. Saat gangguan selesai, lanjut otomatis hanya kalau sistem bilang
    /// `.shouldResume`; kalau tidak, tetap dijeda (layar 14 punya tombol Lanjut manual).
    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            guard state == .recording else { return }
            stopTimers()
            finishCurrentSegment()
            state = .paused(.phoneCall)
        case .ended:
            guard state == .paused(.phoneCall) else { return }
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resume()
            }
        @unknown default:
            break
        }
    }

    /// Perubahan rute (headset lepas, dst). Tidak memaksa jeda — recorder tetap merekam dari
    /// mikrofon yang tersedia, cuma dicatat untuk kemungkinan diagnosa nanti.
    @objc private func handleRouteChange(_ notification: Notification) {
        // Sengaja tidak mengubah state: perubahan rute input bukan gangguan rekaman (D8 scope).
    }

    /// Daemon audio sistem reset (jarang terjadi) — recorder dan sesi lama sudah tidak valid.
    /// Tutup segmen berjalan, jeda, user perlu menekan Lanjut untuk memulai sesi/segmen baru.
    @objc private func handleMediaServicesReset(_ notification: Notification) {
        guard state == .recording else { return }
        stopTimers()
        recorder = nil // sesi lama sudah tidak valid, jangan panggil .stop() padanya
        currentSegment?.durationSeconds = elapsed - currentSegmentStartElapsed
        currentSegment = nil
        state = .paused(.phoneCall)
    }

    static func segmentsDirectory() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("RecordingSegments", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

extension AudioRecorder.State {
    var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {}

