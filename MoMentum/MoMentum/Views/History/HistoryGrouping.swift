import Foundation

/// Filter chip di Riwayat.
enum HistoryFilter: CaseIterable, Identifiable {
    case all
    case done
    case inProgress
    case failed

    var id: Self { self }

    var label: String {
        switch self {
        case .all: "Semua"
        case .done: "Selesai"
        case .inProgress: "Diproses"
        case .failed: "Gagal"
        }
    }

    /// "Diproses" mencakup semua yang belum selesai dan belum gagal: direkam, menunggu, diproses.
    func matches(_ status: MeetingStatus) -> Bool {
        switch self {
        case .all: true
        case .done: status == .done
        case .inProgress: [.recorded, .queued, .processing].contains(status)
        case .failed: status == .failed
        }
    }
}

struct HistorySection: Identifiable {
    var title: String
    var meetings: [Meeting]
    var id: String { title }
}

enum HistoryGrouping {
    /// Saring lalu kelompokkan: HARI INI, MINGGU INI, BULAN INI, lalu per bulan ("OKTOBER 2026").
    /// Urutan meeting di dalam tiap kelompok mengikuti urutan input (terbaru dulu).
    static func sections(
        for meetings: [Meeting],
        filter: HistoryFilter = .all,
        query: String = "",
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [HistorySection] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let visible = meetings.filter { meeting in
            filter.matches(meeting.status)
                && (trimmedQuery.isEmpty || meeting.title.localizedStandardContains(trimmedQuery))
        }

        var sections: [HistorySection] = []
        for meeting in visible {
            let title = sectionTitle(for: meeting.createdAt, now: now, calendar: calendar)
            if let index = sections.firstIndex(where: { $0.title == title }) {
                sections[index].meetings.append(meeting)
            } else {
                sections.append(HistorySection(title: title, meetings: [meeting]))
            }
        }
        return sections
    }

    static func sectionTitle(for date: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return "HARI INI"
        }
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return "MINGGU INI"
        }
        if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            return "BULAN INI"
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).uppercased(with: Locale(identifier: "id_ID"))
    }
}
