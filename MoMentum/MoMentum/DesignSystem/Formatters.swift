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
}
