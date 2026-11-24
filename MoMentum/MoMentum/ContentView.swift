//
//  ContentView.swift
//  MoMentum
//
//  Created by Rasyid Juliansyah on 24/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meeting.createdAt, order: .reverse) private var meetings: [Meeting]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(meetings) { meeting in
                    NavigationLink {
                        Text(meeting.title)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(meeting.title)
                            Text(meeting.createdAt, format: .dateTime)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteMeetings)
            }
            .navigationTitle("MoMentum")
            .toolbar {
                ToolbarItem {
                    Button(action: addPlaceholderMeeting) {
                        Label("Rekam", systemImage: "mic.fill")
                    }
                }
            }
        } detail: {
            Text("Pilih meeting")
        }
    }

    // ponytail: placeholder, ganti dengan alur rekam audio nyata (AudioRecorder service)
    private func addPlaceholderMeeting() {
        withAnimation {
            modelContext.insert(Meeting(title: "Meeting baru"))
        }
    }

    private func deleteMeetings(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(meetings[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Meeting.self, inMemory: true)
}
