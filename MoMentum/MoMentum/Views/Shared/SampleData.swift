import SwiftData
import SwiftUI

/// Data contoh untuk SwiftUI Preview, mengikuti isi layar Riwayat di Figma.
/// Hanya dipakai di `#Preview`, tidak pernah masuk ke data app.
struct SampleData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let container = try ModelContainer(
            for: Meeting.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        for meeting in Meeting.previewSamples() {
            container.mainContext.insert(meeting)
        }
        return container
    }

    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    static var sampleData: Self { .modifier(SampleData()) }
}

extension Meeting {
    static func previewSamples(now: Date = .now) -> [Meeting] {
        func make(_ title: String, daysAgo: Int, minutes: Int, status: MeetingStatus, segments: Int, transcribed: Int) -> Meeting {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let meeting = Meeting(title: title, createdAt: date, status: status)
            meeting.durationSeconds = TimeInterval(minutes * 60)
            for index in 0..<segments {
                let segment = Segment(
                    fileName: "preview-\(index).m4a",
                    startedAt: date.addingTimeInterval(Double(index) * RecordingConstants.segmentDuration)
                )
                segment.transcribed = index < transcribed
                meeting.segments.append(segment)
            }
            return meeting
        }
        return [
            make("Weekly Sync Product", daysAgo: 0, minutes: 118, status: .processing, segments: 8, transcribed: 0),
            make("1:1 dengan Tech Lead", daysAgo: 0, minutes: 42, status: .queued, segments: 3, transcribed: 0),
            make("Review PRD Absen QR", daysAgo: 3, minutes: 134, status: .done, segments: 9, transcribed: 9),
            make("Sprint Planning S24", daysAgo: 5, minutes: 156, status: .failed, segments: 11, transcribed: 6),
        ]
    }
}
