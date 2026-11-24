import SwiftUI

/// Alur rekam: layar 02 (fullScreenCover dari `MainTabView`) → Stop → sheet 03 Simpan rekaman.
/// Stop menjeda rekaman dulu; Batal di sheet kembali ke layar rekam dalam keadaan dijeda.
struct RecordingView: View {
    var context: MeetingContextDraft?

    @Environment(\.dismiss) private var dismiss
    // TODO(UI): ganti dengan `AudioRecorder` dari Services setelah PLAN-logic.md L2 selesai.
    @State private var driver: RecordingDemoDriver
    @State private var isConfirmingExit = false
    @State private var isSaving = false
    private let startedAt: Date

    init(context: MeetingContextDraft? = nil) {
        self.context = context
        let now = Date.now
        startedAt = now
        let draft = context ?? MeetingContextDraft()
        _driver = State(initialValue: RecordingDemoDriver(title: draft.resolvedTitle(at: now), agenda: draft.trimmedAgenda))
    }

    var body: some View {
        RecordingScreen(
            snapshot: driver.snapshot,
            onBack: { isConfirmingExit = true },
            onMark: driver.mark,
            onTogglePause: driver.togglePause,
            onStop: stop
        )
        .onAppear { driver.start() }
        .onDisappear { driver.finish() }
        .confirmationDialog("Rekaman masih berjalan", isPresented: $isConfirmingExit, titleVisibility: .visible) {
            Button("Hentikan & simpan") { stop() }
            Button("Lanjut merekam", role: .cancel) {}
        }
        .sheet(isPresented: $isSaving) {
            SaveRecordingSheet(
                initialDraft: draftForSaving,
                duration: driver.snapshot.elapsed,
                levels: driver.snapshot.levels,
                onSave: { _, _ in
                    // TODO(UI): simpan ke Meeting dan buka layar 05 Memproses setelah service Logic tersedia.
                    driver.finish()
                    dismiss()
                },
                onCancel: { isSaving = false }
            )
        }
    }

    private var draftForSaving: MeetingContextDraft {
        var draft = context ?? MeetingContextDraft()
        draft.title = draft.resolvedTitle(at: startedAt)
        return draft
    }

    private func stop() {
        driver.pause()
        isSaving = true
    }
}

#Preview {
    RecordingView(context: MeetingContextDraft(title: "Weekly Sync Product", agenda: "review sprint & roadmap Q1"))
}
