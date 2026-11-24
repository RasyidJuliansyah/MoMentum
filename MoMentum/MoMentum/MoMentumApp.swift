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
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
