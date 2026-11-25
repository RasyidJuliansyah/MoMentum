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
            // Rekaman contoh sudah ditutup rapi; tanpa ini `AudioRecorder` menganggapnya rekaman yang terputus.
            meeting.endedAt = date.addingTimeInterval(TimeInterval(minutes * 60))
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
        let review = make("Review PRD Absen QR", daysAgo: 3, minutes: 134, status: .done, segments: 9, transcribed: 9)
        addDetailSample(to: review)
        return [
            make("Weekly Sync Product", daysAgo: 0, minutes: 118, status: .processing, segments: 8, transcribed: 0),
            make("1:1 dengan Tech Lead", daysAgo: 0, minutes: 42, status: .queued, segments: 3, transcribed: 0),
            review,
            make("Sprint Planning S24", daysAgo: 5, minutes: 156, status: .failed, segments: 11, transcribed: 6),
        ]
    }

    /// Isi contoh layar 06–08 sesuai Figma.
    private static func addDetailSample(to meeting: Meeting) {
        meeting.summaryText = """
        Tim menyepakati absen QR dipakai untuk sekolah yang melarang HP. Kode QR ditampilkan di IFP kelas dan berganti tiap 30 detik supaya tidak bisa dibagikan.

        Validasi lokasi ditunda ke fase 2. Fokus sprint depan: generator QR dan laporan presensi untuk guru.
        """
        let lines: [(String, Int, String)] = [
            ("RJ", 134_000, "Oke, kita mulai. Fokus hari ini PRD absen QR, terutama untuk sekolah yang melarang HP."),
            ("Dina", 171_000, "Dari sisi guru, yang penting laporan presensi per kelas bisa langsung diunduh."),
            ("Speaker 4", 245_000, "IFP saja. QR-nya tampil di layar kelas, siswa absen pakai kartu."),
            ("Bayu", 312_000, "QR bisa berganti tiap 30 detik supaya tidak bisa difoto lalu dibagikan."),
            ("RJ", 398_000, "Setuju. Validasi lokasi kita tunda ke fase 2."),
        ]
        if let first = meeting.segments.first {
            for (speaker, start, text) in lines {
                first.utterances.append(Utterance(speakerLabel: speaker, startMs: start, endMs: start + 20_000, text: text))
            }
        }
        meeting.actionItems.append(ActionItem(task: "Buat generator QR dinamis (rotasi 30 detik)", pic: "Bayu", dueDate: "28 Nov"))
        meeting.actionItems.append(ActionItem(task: "Susun laporan presensi per kelas", pic: "Dina", dueDate: "2 Des"))
        meeting.actionItems.append(ActionItem(task: "Cek kebijakan HP di 3 sekolah pilot", pic: "PIC belum jelas"))
        meeting.actionItems.append(ActionItem(task: "Kirim PRD revisi ke tim", pic: "RJ", dueDate: "26 Nov"))
        meeting.actionItems.append(ActionItem(task: "Draft validasi lokasi untuk fase 2", pic: "RJ"))
    }
}
