import AVFoundation
import SwiftData
import SwiftUI

/// Alur rekam: layar 02 (fullScreenCover dari `MainTabView`) → Stop → sheet 03 Simpan rekaman.
/// Stop menjeda rekaman dulu; Batal di sheet kembali ke layar rekam dalam keadaan dijeda.
/// Rekaman baru ditutup (`AudioRecorder.stop()`) saat user menekan Simpan.
struct RecordingView: View {
    var context: MeetingContextDraft?
    /// Dipanggil setelah rekaman tersimpan, supaya `MainTabView` bisa membuka Riwayat.
    var onSaved: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Environment(AudioRecorder.self) private var recorder
    @Environment(MeetingProcessor.self) private var processor
    @State private var isConfirmingExit = false
    @State private var isSaving = false
    @State private var isMicrophoneDenied = false
    private let startedAt: Date
    private let draft: MeetingContextDraft

    init(context: MeetingContextDraft? = nil, onSaved: @escaping () -> Void = {}) {
        self.context = context
        self.onSaved = onSaved
        startedAt = .now
        draft = context ?? MeetingContextDraft()
    }

    var body: some View {
        let snapshot = RecordingSnapshot(recorder: recorder, title: draft.resolvedTitle(at: startedAt), agenda: draft.trimmedAgenda)
        RecordingScreen(
            snapshot: snapshot,
            onBack: { isConfirmingExit = true },
            onMark: recorder.mark,
            onTogglePause: togglePause,
            onStop: stop
        )
        .task { await start() }
        .confirmationDialog("Rekaman masih berjalan", isPresented: $isConfirmingExit, titleVisibility: .visible) {
            Button("Hentikan & simpan") { stop() }
            Button("Lanjut merekam", role: .cancel) {}
        }
        .alert("Izin mikrofon belum diberikan", isPresented: $isMicrophoneDenied) {
            Button("Buka Pengaturan iPhone") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                dismiss()
            }
            Button("Tutup", role: .cancel) { dismiss() }
        } message: {
            Text("MoMentum butuh mikrofon untuk merekam meeting. Aktifkan di Pengaturan iPhone › MoMentum › Mikrofon.")
        }
        .sheet(isPresented: $isSaving) {
            SaveRecordingSheet(
                initialDraft: draftForSaving,
                duration: snapshot.elapsed,
                levels: snapshot.levels,
                onSave: save,
                onCancel: { isSaving = false }
            )
        }
    }

    private var draftForSaving: MeetingContextDraft {
        var draft = draft
        draft.title = draft.resolvedTitle(at: startedAt)
        return draft
    }

    private func start() async {
        guard recorder.state == .idle || recorder.state == .finished else { return }
        guard await Self.hasMicrophonePermission() else {
            isMicrophoneDenied = true
            return
        }
        recorder.start(
            title: draft.resolvedTitle(at: startedAt),
            agenda: draft.trimmedAgenda,
            glossaryTerms: draft.terms
        )
    }

    private static func hasMicrophonePermission() async -> Bool {
        #if DEBUG
        // UI test di simulator: dialog izin sistem akan menutupi layar. Tanpa izin, perekam tetap
        // jalan (merekam hening), cukup untuk menguji alur.
        if UITestSupport.requestedSeed != nil { return true }
        #endif
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return true
        case .denied: return false
        default: return await AVAudioApplication.requestRecordPermission()
        }
    }

    private func togglePause() {
        if recorder.state == .recording {
            recorder.pause()
        } else {
            recorder.resume()
        }
    }

    private func stop() {
        recorder.pause()
        isSaving = true
    }

    private func save(_ final: MeetingContextDraft, processNow: Bool) {
        guard let meeting = recorder.meeting else {
            dismiss()
            return
        }
        meeting.title = final.resolvedTitle(at: startedAt)
        meeting.agenda = final.trimmedAgenda
        meeting.glossaryTerms = final.terms
        recorder.stop()
        try? modelContext.save()
        if processNow {
            meeting.status = .queued
            processor.process(meeting)
        }
        isSaving = false
        onSaved()
        dismiss()
    }
}
