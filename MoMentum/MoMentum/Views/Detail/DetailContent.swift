import Foundation

/// Tab di layar Detail meeting (06–08).
enum DetailTab: String, CaseIterable, Identifiable {
    case summary
    case actionItems
    case transcript
    case mom

    var id: Self { self }

    var label: String {
        switch self {
        case .summary: "Ringkasan"
        case .actionItems: "Action items"
        case .transcript: "Transkrip"
        case .mom: "MoM"
        }
    }
}

/// Satu speaker di meeting, diturunkan dari utterance.
struct SpeakerInfo: Identifiable, Equatable {
    var label: String
    var occurrences: Int
    var firstStartMs: Int
    var firstQuote: String
    /// Urutan kemunculan, dipakai untuk warna avatar.
    var order: Int

    var id: String { label }

    /// Label bawaan "Speaker 4" berarti belum diberi nama.
    var isNamed: Bool { !label.hasPrefix("Speaker ") }

    /// Isi avatar: inisial nama, atau nomor untuk speaker tanpa nama.
    var avatarText: String {
        isNamed ? String(label.prefix(1)).uppercased() : String(label.dropFirst("Speaker ".count))
    }
}

/// Satu baris transkrip.
struct TranscriptLine: Identifiable, Equatable {
    var id: Int
    var speakerLabel: String
    var startMs: Int
    var text: String
}

/// Isi layar Detail yang dihitung dari `Meeting`.
struct MeetingDetailContent: Equatable {
    var title: String
    var status: MeetingStatus
    var dateText: String
    var durationText: String
    var summaryParagraphs: [String]
    var actionItems: [ActionItemContent]
    var speakers: [SpeakerInfo]
    var transcript: [TranscriptLine]

    var participantCount: Int { speakers.count }

    init(meeting: Meeting) {
        title = meeting.title
        status = meeting.status
        dateText = meeting.createdAt.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "id_ID")))
        durationText = MFormat.duration(meeting.durationSeconds)
        summaryParagraphs = (meeting.summaryText ?? "")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // Utterance.startMs dihitung dari awal audio meeting (PLAN-logic.md L1.4).
        let utterances = meeting.segments
            .sorted { $0.startedAt < $1.startedAt }
            .flatMap { $0.utterances.sorted { $0.startMs < $1.startMs } }
        transcript = utterances.enumerated().map { index, utterance in
            TranscriptLine(id: index, speakerLabel: utterance.speakerLabel, startMs: utterance.startMs, text: utterance.text)
        }
        speakers = Self.speakers(from: transcript)
        actionItems = meeting.actionItems.map { ActionItemContent(item: $0) }
    }

    /// Speaker urut kemunculan. Warna avatar (`order`) hanya dihitung di antara speaker bernama,
    /// supaya speaker tanpa nama (abu-abu) tidak menghabiskan slot warna.
    static func speakers(from lines: [TranscriptLine]) -> [SpeakerInfo] {
        var result: [SpeakerInfo] = []
        var namedCount = 0
        for line in lines {
            if let index = result.firstIndex(where: { $0.label == line.speakerLabel }) {
                result[index].occurrences += 1
            } else {
                var speaker = SpeakerInfo(
                    label: line.speakerLabel,
                    occurrences: 1,
                    firstStartMs: line.startMs,
                    firstQuote: line.text,
                    order: 0
                )
                if speaker.isNamed {
                    speaker.order = namedCount
                    namedCount += 1
                }
                result.append(speaker)
            }
        }
        return result
    }

    func speaker(named label: String) -> SpeakerInfo? {
        speakers.first { $0.label == label }
    }
}

/// Satu action item untuk ditampilkan (Figma: Action Item Row).
struct ActionItemContent: Equatable, Identifiable {
    var id: String { task }
    var task: String
    /// `nil` kalau PIC belum jelas.
    var pic: String?
    var due: String?

    static let unclearPIC = "PIC belum jelas"

    init(task: String, pic: String?, due: String?) {
        self.task = task
        let trimmed = pic?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.pic = trimmed.isEmpty || trimmed == Self.unclearPIC ? nil : trimmed
        self.due = due
    }

    init(item: ActionItem) {
        self.init(task: item.task, pic: item.pic, due: item.dueDate)
    }
}
