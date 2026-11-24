import Foundation

/// Angka kartu "Aktivitas minggu ini" di Beranda.
struct WeeklyStats: Equatable {
    var meetingCount = 0
    var recordedSeconds: TimeInterval = 0
    var momReadyCount = 0

    init(meetingCount: Int = 0, recordedSeconds: TimeInterval = 0, momReadyCount: Int = 0) {
        self.meetingCount = meetingCount
        self.recordedSeconds = recordedSeconds
        self.momReadyCount = momReadyCount
    }

    /// Hitung dari meeting yang dibuat di minggu kalender yang sama dengan `now`.
    init(meetings: [Meeting], now: Date = .now, calendar: Calendar = .current) {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return }
        let thisWeek = meetings.filter { week.contains($0.createdAt) }
        meetingCount = thisWeek.count
        recordedSeconds = thisWeek.reduce(0) { $0 + $1.durationSeconds }
        momReadyCount = thisWeek.filter { $0.status == .done }.count
    }
}
