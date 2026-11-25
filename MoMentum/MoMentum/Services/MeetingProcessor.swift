import Foundation
import SwiftData

/// L6: jalankan langkah layar 05 berurutan untuk satu `Meeting` (saved → uploaded →
/// transcribing → summarizing), perbarui `status`/`processingStep`, dan simpan cukup state
/// (`providerJobId`, file gabungan sementara) supaya "coba lagi" melanjutkan dari langkah yang
/// gagal tanpa upload ulang (hemat biaya, idempoten per langkah).
///
/// Satu meeting diproses dalam satu waktu (`activeMeetingID`) — proses kedua untuk meeting lain
/// yang masuk saat satu proses masih jalan ditahan di `pendingQueue` (lihat `process(_:)`).
@Observable
final class MeetingProcessor {
    /// Progres 0...1 untuk `ProgressRing` (layar 05), per meeting yang sedang diproses.
    private(set) var progressByMeetingID: [PersistentIdentifier: Double] = [:]

    private let modelContext: ModelContext
    private let transcriptionProvider: TranscriptionProvider
    private let summaryProvider: SummaryProvider
    private let notifier: (String, String) async -> Void

    private var activeMeetingID: PersistentIdentifier?
    private var pendingQueue: [Meeting] = []

    init(
        modelContext: ModelContext,
        transcriptionProvider: TranscriptionProvider,
        summaryProvider: SummaryProvider,
        notifier: @escaping (String, String) async -> Void = MeetingNotifier.notifyMoMReady
    ) {
        self.modelContext = modelContext
        self.transcriptionProvider = transcriptionProvider
        self.summaryProvider = summaryProvider
        self.notifier = notifier
    }

    // MARK: - Generate ulang ringkasan (L7, requirement S)

    /// Dipakai tombol "Generate ulang" (layar 06) atau toggle di sheet ganti nama speaker.
    /// Memakai transkrip (`Utterance`) yang SUDAH tersimpan lokal — tidak transkripsi ulang,
    /// tidak upload ulang. Meeting harus sudah pernah selesai transkripsi (`processingStep`
    /// minimal `.transcribing`), kalau belum tidak ada transkrip untuk diringkas.
    func regenerateSummary(_ meeting: Meeting) {
        guard meeting.processingStep == .transcribing || meeting.processingStep == .summarizing else { return }
        let id = meeting.persistentModelID
        guard activeMeetingID != id, !pendingQueue.contains(where: { $0.persistentModelID == id }) else { return }

        meeting.status = .processing
        if activeMeetingID == nil {
            activeMeetingID = id
            Task {
                await BackgroundTaskCoordinator.withBackgroundTask {
                    do {
                        try await self.summarizeStep(meeting)
                    } catch {
                        self.handleFailure(meeting, error: error)
                    }
                }
                self.activeMeetingID = nil
                self.progressByMeetingID[id] = nil
                self.advanceQueue()
            }
        } else {
            pendingQueue.append(meeting)
        }
    }

    // MARK: - API untuk UI (L6.3)

    /// Dipanggil saat "Simpan & proses" ditekan, app diluncurkan/kembali ke depan dengan meeting
    /// `.queued`/`.processing` tertinggal, atau koneksi pulih (`NetworkMonitor`).
    func process(_ meeting: Meeting) {
        guard meeting.status != .done else { return }
        enqueue(meeting)
    }

    /// Tombol "Coba lagi" (layar 13) — melanjutkan dari `processingStep` yang gagal, bukan dari awal.
    func retry(_ meeting: Meeting) {
        meeting.lastErrorKind = nil
        meeting.lastErrorMessage = nil
        enqueue(meeting)
    }

    private func enqueue(_ meeting: Meeting) {
        let id = meeting.persistentModelID
        guard activeMeetingID != id, !pendingQueue.contains(where: { $0.persistentModelID == id }) else { return }
        if activeMeetingID == nil {
            runMeeting(meeting)
        } else {
            pendingQueue.append(meeting)
        }
    }

    // MARK: - Orchestration (L6.1)

    private func runMeeting(_ meeting: Meeting) {
        let id = meeting.persistentModelID
        activeMeetingID = id
        meeting.status = .processing
        progressByMeetingID[id] = progress(for: meeting.processingStep)

        Task {
            await BackgroundTaskCoordinator.withBackgroundTask {
                await self.runSteps(meeting)
            }
            self.activeMeetingID = nil
            self.progressByMeetingID[id] = nil
            self.advanceQueue()
        }
    }

    private func advanceQueue() {
        guard activeMeetingID == nil, !pendingQueue.isEmpty else { return }
        runMeeting(pendingQueue.removeFirst())
    }

    /// Progres kasar untuk `ProgressRing`, 1 dari 4 langkah = 0.25 dst. `nil` (belum mulai) = 0.
    private func progress(for step: ProcessingStep?) -> Double {
        switch step {
        case nil: 0
        case .saved: 0.25
        case .uploaded: 0.5
        case .transcribing: 0.75
        case .summarizing: 1
        }
    }

    /// Menjalankan langkah yang BELUM selesai, dimulai dari `meeting.processingStep` tersimpan —
    /// inilah yang membuat "coba lagi" idempoten (tidak upload ulang kalau sudah `.uploaded`, dst).
    private func runSteps(_ meeting: Meeting) async {
        do {
            if meeting.processingStep == nil {
                meeting.processingStep = .saved
                progressByMeetingID[meeting.persistentModelID] = progress(for: .saved)
            }
            if meeting.processingStep == .saved {
                try await uploadStep(meeting)
            }
            if meeting.processingStep == .uploaded {
                try await transcribeStep(meeting)
            }
            // `.summarizing` tapi belum `.done`: generate ulang yang gagal lalu dicoba lagi.
            if meeting.processingStep == .transcribing || meeting.processingStep == .summarizing {
                try await summarizeStep(meeting)
            }
        } catch {
            handleFailure(meeting, error: error)
        }
    }

    private func uploadStep(_ meeting: Meeting) async throws {
        let sortedSegments = meeting.segments.sorted { $0.index < $1.index }
        let segmentURLs = sortedSegments.map {
            AudioRecorder.segmentsDirectory().appendingPathComponent($0.fileName)
        }
        let mergedURL = try await AudioMerger.merge(segmentURLs: segmentURLs)
        defer { try? FileManager.default.removeItem(at: mergedURL) }

        let jobId = try await transcriptionProvider.submit(
            audioFileURL: mergedURL,
            options: TranscriptionOptions(glossaryTerms: meeting.glossaryTerms)
        )
        meeting.providerJobId = jobId
        meeting.processingStep = .uploaded
        progressByMeetingID[meeting.persistentModelID] = progress(for: .uploaded)
    }

    private func transcribeStep(_ meeting: Meeting) async throws {
        guard let jobId = meeting.providerJobId else {
            throw TranscriptionError.unknown("providerJobId hilang, tidak bisa polling")
        }
        let result = try await transcriptionProvider.pollUntilComplete(jobId: jobId)
        let normalized = SpeakerLabelNormalizer.normalize(result.utterances, meeting: meeting, context: modelContext)

        // Satu segmen gabungan menampung semua utterance (D2 = A, satu file per meeting).
        let targetSegment = meeting.segments.sorted { $0.index < $1.index }.first
        for utterance in normalized {
            let model = Utterance(
                speakerLabel: utterance.speakerLabel,
                startMs: utterance.startMs,
                endMs: utterance.endMs,
                text: utterance.text
            )
            targetSegment?.utterances.append(model)
            modelContext.insert(model)
        }

        meeting.processingStep = .transcribing
        meeting.transcriptionAudioSeconds = result.audioDurationSeconds
        progressByMeetingID[meeting.persistentModelID] = progress(for: .transcribing)

        // D6: hasil sudah tersimpan lokal (Utterance di atas), hapus dari server vendor.
        await transcriptionProvider.deleteTranscript(jobId: jobId)
    }

    private func summarizeStep(_ meeting: Meeting) async throws {
        let allUtterances = meeting.segments
            .sorted { $0.index < $1.index }
            .flatMap(\.utterances)
            .sorted { $0.startMs < $1.startMs }

        let input = SummaryInput(
            meetingTitle: meeting.title,
            agenda: meeting.agenda,
            glossaryTerms: meeting.glossaryTerms,
            markerOffsetsMs: meeting.markerOffsets.map { Int($0 * 1000) },
            transcript: allUtterances.map {
                SummaryInput.Line(speakerName: meeting.displayName(for: $0.speakerLabel), startMs: $0.startMs, text: $0.text)
            }
        )
        let result = try await summaryProvider.summarize(input)

        meeting.summaryText = result.summaryText
        meeting.topics = result.topics
        meeting.decisions = result.decisions
        meeting.summaryPromptTokens = result.promptTokens
        meeting.summaryCompletionTokens = result.completionTokens
        // Generate ulang (L7) bisa memanggil ini lebih dari sekali — buang action items lama
        // dulu supaya tidak duplikat, bukan isDone-nya (checkbox) hilang percuma di alur normal
        // karena di alur normal daftar ini memang masih kosong.
        for old in meeting.actionItems {
            modelContext.delete(old)
        }
        meeting.actionItems.removeAll()
        for (index, item) in result.actionItems.enumerated() {
            let model = ActionItem(task: item.task, pic: item.pic, dueDate: item.dueDate, order: index)
            meeting.actionItems.append(model)
            modelContext.insert(model)
        }

        meeting.processingStep = .summarizing
        meeting.processedAt = .now
        meeting.status = .done
        progressByMeetingID[meeting.persistentModelID] = progress(for: .summarizing)

        await notifier(meeting.title, String(describing: meeting.persistentModelID))
    }

    /// Memetakan error provider ke `Meeting.lastErrorKind`/`lastErrorMessage` (layar 13).
    /// Error jaringan -> `.queued` (requirement S: lanjut otomatis saat koneksi pulih), bukan `.failed`.
    private func handleFailure(_ meeting: Meeting, error: Error) {
        switch error {
        case TranscriptionError.network, SummaryError.network:
            meeting.status = .queued
            return
        case TranscriptionError.missingAPIKey, SummaryError.missingAPIKey,
             TranscriptionError.invalidAPIKey, SummaryError.invalidAPIKey:
            meeting.lastErrorKind = .invalidAPIKey
            meeting.lastErrorMessage = "API key belum diisi atau tidak valid. Cek API key di Pengaturan."
        case TranscriptionError.vendor(let message), SummaryError.vendor(let message):
            meeting.lastErrorKind = .vendor
            meeting.lastErrorMessage = message
        case SummaryError.invalidResponse(let message):
            meeting.lastErrorKind = .vendor
            meeting.lastErrorMessage = message
        case AudioMergerError.noSegments:
            meeting.lastErrorKind = .unknown
            meeting.lastErrorMessage = "Rekaman kosong, tidak ada audio yang bisa diproses. Cek izin mikrofon lalu rekam ulang."
        case AudioMergerError.exportFailed(let message):
            meeting.lastErrorKind = .unknown
            meeting.lastErrorMessage = "File rekaman gagal digabung: \(message)"
        default:
            meeting.lastErrorKind = .unknown
            meeting.lastErrorMessage = "Terjadi kesalahan tak terduga. Coba lagi."
        }
        meeting.status = .failed
    }
}
