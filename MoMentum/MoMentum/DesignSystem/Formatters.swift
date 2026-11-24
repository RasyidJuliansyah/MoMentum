import Foundation

/// Format teks yang dipakai berulang di UI.
enum MFormat {
    /// Durasi ringkas gaya Figma: "1j 58m", "42m", "2j". Di bawah 1 menit jadi "0m".
    static func duration(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        switch (hours, minutes) {
        case (0, _): return "\(minutes)m"
        case (_, 0): return "\(hours)j"
        default: return "\(hours)j \(minutes)m"
        }
    }

    /// Jam digital "01:12:48" untuk timer rekaman dan penanda momen.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    /// Kalimat untuk VoiceOver, misalnya "1 jam 12 menit 48 detik".
    static func spokenDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let parts = [(total / 3600, "jam"), ((total % 3600) / 60, "menit"), (total % 60, "detik")]
            .filter { $0.0 > 0 }
            .map { "\($0.0) \($0.1)" }
        return parts.isEmpty ? "0 detik" : parts.joined(separator: " ")
    }
}
