import SwiftUI

/// Layar 05 Memproses dan 13 Proses gagal untuk satu meeting (di-push dari Riwayat).
struct ProcessingView: View {
    let meeting: Meeting

    @Environment(\.openSettings) private var openSettings

    var body: some View {
        ProcessingScreen(
            content: ProcessingContent(meeting: meeting),
            onRetry: {
                // TODO(UI): MeetingProcessor.retry(meeting) setelah PLAN-logic.md L6.3 selesai.
            },
            onProcessNow: {
                // TODO(UI): MeetingProcessor.process(meeting) setelah PLAN-logic.md L6.3 selesai.
            },
            onCheckAPIKey: { openSettings() }
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}
