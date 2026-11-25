//
//  MoMentumApp.swift
//  MoMentum
//
//  Created by Rasyid Juliansyah on 24/11/26.
//

import SwiftUI
import SwiftData

@main
struct MoMentumApp: App {
    var sharedModelContainer: ModelContainer = {
        #if DEBUG
        // UI test: service juga harus memakai database in-memory, bukan data asli di perangkat.
        if let container = UITestSupport.container { return container }
        #endif
        let schema = Schema([
            Meeting.self,
            Segment.self,
            Utterance.self,
            ActionItem.self,
            Speaker.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let meetingProcessor: MeetingProcessor
    private let networkMonitor = NetworkMonitor()
    /// Satu perekam untuk seluruh app. Jangan dibuat di `body`: `body` dihitung ulang berkali-kali
    /// dan perekam baru akan memutus rekaman yang sedang berjalan.
    private let audioRecorder: AudioRecorder

    init() {
        let context = sharedModelContainer.mainContext
        let processor = MeetingProcessor(
            modelContext: context,
            transcriptionProvider: AssemblyAITranscriptionProvider(),
            // Key `sk-ant-` ke Claude, key lain ke endpoint OpenAI-compatible.
            summaryProvider: AutoSummaryProvider()
        )
        meetingProcessor = processor
        audioRecorder = AudioRecorder(modelContext: context)
        // D5: retensi 30 hari default (lihat AppStorageKey.audioRetentionDays, wilayah UI).
        // Kunci dibaca langsung di sini karena belum ada constant bersama; kalau sesi UI
        // mengubah nama kunci, sesuaikan string di bawah.
        let retentionDays = UserDefaults.standard.object(forKey: "audioRetentionDays") as? Int ?? 30
        AudioRetentionCleaner.deleteExpiredAudio(in: context, retentionDays: retentionDays)
        // L6.2: lanjutan proses dibangunkan iOS lewat BGTaskScheduler (D9). Harus didaftarkan
        // sebelum scene muncul (dokumentasi Apple), jadi di sini, bukan di `.task` view.
        BackgroundTaskCoordinator.registerBackgroundTask {
            let queued = MeetingStatus.queued
            let processing = MeetingStatus.processing
            let unfinished = (try? context.fetch(
                FetchDescriptor<Meeting>(predicate: #Predicate { $0.status == queued || $0.status == processing })
            )) ?? []
            for meeting in unfinished {
                processor.process(meeting)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioRecorder)
                .environment(meetingProcessor)
                .environment(networkMonitor)
        }
        .modelContainer(sharedModelContainer)
    }
}
