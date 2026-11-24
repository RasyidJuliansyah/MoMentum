import Foundation

/// Isi MoM (layar 08) dengan format PRD: info meeting, peserta, topik, keputusan, action items.
/// Dipakai untuk tampilan, salin, dan bagikan (teks atau Markdown).
struct MoMDocument: Equatable {
    var title: String
    var dateText: String
    var timeText: String
    var participants: [String]
    var notetaker = "MoMentum"
    /// TODO(UI): isi dari Meeting setelah sesi Logic menyimpan topik dan keputusan terstruktur (handover 3a).
    var topics: [String] = []
    var decisions: [String] = []
    var actionItems: [ActionItemContent]

    init(
        title: String,
        dateText: String,
        timeText: String,
        participants: [String],
        topics: [String] = [],
        decisions: [String] = [],
        actionItems: [ActionItemContent]
    ) {
        self.title = title
        self.dateText = dateText
        self.timeText = timeText
        self.participants = participants
        self.topics = topics
        self.decisions = decisions
        self.actionItems = actionItems
    }

    init(meeting: Meeting, content: MeetingDetailContent, timeZone: TimeZone = .current) {
        self.init(
            title: meeting.title,
            dateText: content.dateText,
            timeText: Self.timeRange(start: meeting.createdAt, duration: meeting.durationSeconds, timeZone: timeZone),
            participants: content.speakers.map(\.label),
            actionItems: content.actionItems
        )
    }

    /// "RJ, Dina, Bayu, Pak Hendra, +2".
    var participantsText: String {
        guard participants.count > 4 else { return participants.joined(separator: ", ") }
        return (participants.prefix(4) + ["+\(participants.count - 4)"]).joined(separator: ", ")
    }

    /// "09.00–11.14 WIB".
    static func timeRange(start: Date, duration: TimeInterval, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        func clock(_ date: Date) -> String {
            let parts = calendar.dateComponents([.hour, .minute], from: date)
            return String(format: "%02d.%02d", parts.hour ?? 0, parts.minute ?? 0)
        }
        return "\(clock(start))–\(clock(start.addingTimeInterval(duration))) \(zoneName(timeZone, at: start))"
    }

    static func zoneName(_ timeZone: TimeZone, at date: Date) -> String {
        switch timeZone.secondsFromGMT(for: date) {
        case 7 * 3600: "WIB"
        case 8 * 3600: "WITA"
        case 9 * 3600: "WIT"
        default: timeZone.abbreviation(for: date) ?? timeZone.identifier
        }
    }

    private func actionLine(_ item: ActionItemContent) -> String {
        let owner = [item.pic ?? ActionItemContent.unclearPIC, item.due].compactMap { $0 }.joined(separator: " · ")
        return "\(item.task) — \(owner)"
    }

    func markdown() -> String {
        var lines = [
            "# MoM: \(title)",
            "",
            "- **Tanggal:** \(dateText)",
            "- **Waktu:** \(timeText)",
            "- **Peserta:** \(participants.joined(separator: ", "))",
            "- **Notulis:** \(notetaker)",
        ]
        if !topics.isEmpty {
            lines += ["", "## Topik"] + topics.enumerated().map { "\($0.offset + 1). \($0.element)" }
        }
        if !decisions.isEmpty {
            lines += ["", "## Keputusan"] + decisions.map { "- \($0)" }
        }
        if !actionItems.isEmpty {
            lines += ["", "## Action items"] + actionItems.map { "- [ ] \(actionLine($0))" }
        }
        return lines.joined(separator: "\n")
    }

    func plainText() -> String {
        var lines = [
            "MINUTES OF MEETING",
            title,
            "",
            "Tanggal: \(dateText)",
            "Waktu: \(timeText)",
            "Peserta: \(participants.joined(separator: ", "))",
            "Notulis: \(notetaker)",
        ]
        if !topics.isEmpty {
            lines += ["", "Topik"] + topics.enumerated().map { "\($0.offset + 1). \($0.element)" }
        }
        if !decisions.isEmpty {
            lines += ["", "Keputusan"] + decisions.map { "• \($0)" }
        }
        if !actionItems.isEmpty {
            lines += ["", "Action items"] + actionItems.map { "• \(actionLine($0))" }
        }
        return lines.joined(separator: "\n")
    }
}
