import Foundation

/// Sapaan berdasarkan jam: pagi, siang, sore, malam.
enum Greeting {
    static func text(for date: Date, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 4..<11: "Selamat pagi"
        case 11..<15: "Selamat siang"
        case 15..<18: "Selamat sore"
        default: "Selamat malam"
        }
    }

    /// Inisial maksimal dua huruf untuk avatar, misalnya "Rasyid Juliansyah" → "RJ".
    static func initials(of name: String) -> String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map { String($0).uppercased() }
            .joined()
    }
}
