import Foundation

/// Masa berlaku profil instalasi. Dengan Apple Account gratis profil habis 7 hari setelah build (PRD),
/// jadi Pengaturan mengingatkan kapan perlu build ulang dari Xcode.
enum ProvisioningProfile {
    enum Status: Equatable {
        /// Tidak ada profil (simulator atau build App Store).
        case unavailable
        case expired
        case expiring(daysLeft: Int)
        case valid(until: Date)
    }

    /// Ambil `ExpirationDate` dari isi `embedded.mobileprovision` (plist di dalam data bertanda tangan CMS).
    static func expirationDate(fromProfileData data: Data) -> Date? {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), in: start.lowerBound..<data.endIndex) else {
            return nil
        }
        let plistData = data.subdata(in: start.lowerBound..<end.upperBound)
        let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any]
        return plist?["ExpirationDate"] as? Date
    }

    static func currentStatus(now: Date = .now, calendar: Calendar = .current) -> Status {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url) else {
            return .unavailable
        }
        return status(expiration: expirationDate(fromProfileData: data), now: now, calendar: calendar)
    }

    static func status(expiration: Date?, now: Date, calendar: Calendar) -> Status {
        guard let expiration else { return .unavailable }
        if expiration <= now { return .expired }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: expiration)
        ).day ?? 0
        return days <= 7 ? .expiring(daysLeft: days) : .valid(until: expiration)
    }
}
