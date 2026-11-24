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

    init() {
        let context = sharedModelContainer.mainContext
        let processor = MeetingProcessor(
            modelContext: context,
            transcriptionProvider: AssemblyAITranscriptionProvider(),
            summaryProvider: OpenAICompatibleSummaryProvider(
                baseURL: URL(string: "https://api.openai.com/v1")!,
                model: "gpt-4o-mini"
            )
        )
        meetingProcessor = processor
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
                .environment(AudioRecorder(modelContext: sharedModelContainer.mainContext))
                .environment(meetingProcessor)
                .environment(networkMonitor)
        }
        .modelContainer(sharedModelContainer)
    }
}
