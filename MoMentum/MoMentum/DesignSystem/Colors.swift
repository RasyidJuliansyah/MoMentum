import SwiftUI

extension Color {
    /// Warna dari nilai hex 0xRRGGBB, sesuai variable `MoMentum / Color` di Figma.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Token warna MoMentum. Sumber: variable collection `MoMentum / Color` di Figma
/// (lihat docs/design-handoff.md bagian 3). Warna aksen app (`AccentColor`) = `brand700`.
enum MColor {
    // Brand (hijau evergreen)
    static let brand900 = Color(hex: 0x163A30)
    static let brand700 = Color(hex: 0x2C5E4F) // warna utama: tombol rekam, tab aktif
    static let brand500 = Color(hex: 0x4F8574)
    static let brand300 = Color(hex: 0x9FC2B5)
    static let brand100 = Color(hex: 0xDCEAE4)
    static let brand50 = Color(hex: 0xEEF4F1)

    // Neutral
    static let n0 = Color(hex: 0xFFFFFF)
    static let n50 = Color(hex: 0xF5F7F6)
    static let n100 = Color(hex: 0xEBEFED)
    static let n200 = Color(hex: 0xDCE2DF)
    static let n400 = Color(hex: 0xA3ADA8)
    static let n600 = Color(hex: 0x66716C) // teks sekunder
    static let n900 = Color(hex: 0x101714) // teks utama, tombol primer

    // Aksen dan status
    static let record = Color(hex: 0xF25C2A) // titik merah saat merekam
    static let info = Color(hex: 0x3E73D6)
    static let infoBg = Color(hex: 0xE5EDFB)
    static let warn = Color(hex: 0xC98314)
    static let warnBg = Color(hex: 0xFBF0DC)
    static let danger = Color(hex: 0xD24343)
    static let dangerBg = Color(hex: 0xFBE6E6)
    static let success = Color(hex: 0x2E8A5C)
    static let successBg = Color(hex: 0xDFF2E8)
    static let neutralBg = Color(hex: 0xEBEFED)
}
