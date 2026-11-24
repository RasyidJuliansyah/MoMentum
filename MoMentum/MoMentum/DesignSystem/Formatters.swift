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

    /// Ukuran penyimpanan gaya iOS (1 GB = 1.000.000.000 byte) dengan koma desimal: "1,2 GB", "412 MB".
    static func storage(_ bytes: Int64) -> String {
        let indonesian = Locale(identifier: "id_ID")
        let gigabytes = Double(max(0, bytes)) / 1_000_000_000
        if gigabytes >= 1 {
            return gigabytes.formatted(.number.precision(.fractionLength(1)).locale(indonesian)) + " GB"
        }
        let megabytes = Double(max(0, bytes)) / 1_000_000
        return megabytes.formatted(.number.precision(.fractionLength(0)).locale(indonesian)) + " MB"
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
