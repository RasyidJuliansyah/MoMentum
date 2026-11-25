import SwiftData
import SwiftUI

/// Melanjutkan meeting yang belum selesai diproses (PRD: "Proses otomatis saat online" dan "Proses di
/// background"): saat app dibuka atau kembali ke depan, dan saat koneksi pulih. Saat app ke background,
/// minta iOS membangunkan app nanti (`BGTaskScheduler`) kalau masih ada yang tertunda.
private struct ProcessingResumer: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(MeetingProcessor.self) private var processor
    @Environment(NetworkMonitor.self) private var network

    func body(content: Content) -> some View {
        content
            .task { resumePending() }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    resumePending()
                case .background:
                    try? modelContext.save()
                    if !pendingMeetings().isEmpty {
                        BackgroundTaskCoordinator.scheduleProcessingContinuation()
                    }
                default:
                    break
                }
            }
            .onChange(of: network.isConnected) { _, connected in
                if connected { resumePending() }
            }
    }

    /// `.queued` (antre/offline) dan `.processing` (terputus karena app ditutup). `.failed` tidak diulang
    /// otomatis supaya error yang sama (mis. key salah) tidak menghabiskan kuota; user menekan Coba lagi.
    private func pendingMeetings() -> [Meeting] {
        let queued = MeetingStatus.queued
        let processing = MeetingStatus.processing
        let descriptor = FetchDescriptor<Meeting>(
            predicate: #Predicate { $0.status == queued || $0.status == processing },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func resumePending() {
        #if DEBUG
        // UI test memakai data contoh; jangan kirim ke vendor sungguhan.
        if UITestSupport.requestedSeed != nil { return }
        #endif
        guard network.isConnected else { return }
        for meeting in pendingMeetings() {
            processor.process(meeting)
        }
    }
}

extension View {
    func resumesPendingProcessing() -> some View {
        modifier(ProcessingResumer())
    }
}
