import SwiftData
import SwiftUI

/// Layar 05 Memproses dan 13 Proses gagal untuk satu meeting (di-push dari Riwayat).
struct ProcessingView: View {
    let meeting: Meeting

    @Environment(\.openSettings) private var openSettings
    @Environment(MeetingProcessor.self) private var processor

    var body: some View {
        ProcessingScreen(
            content: ProcessingContent(
                meeting: meeting,
                liveProgress: processor.progressByMeetingID[meeting.persistentModelID]
            ),
            onRetry: { processor.retry(meeting) },
            onProcessNow: { processor.process(meeting) },
            onCheckAPIKey: { openSettings() }
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}
