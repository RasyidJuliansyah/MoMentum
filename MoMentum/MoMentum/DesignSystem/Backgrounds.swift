import SwiftUI

/// Gradien latar layar (atas ke bawah). Lihat docs/design-handoff.md bagian 3.
enum MBackground {
    /// Layar rekam, beranda, onboarding. Sepertiga bawah gelap, jadi teks di sana putih.
    static let deep = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xFFFFFF), location: 0.0),
            .init(color: Color(hex: 0xF1F6F3), location: 0.4),
            .init(color: Color(hex: 0xA9C8BC), location: 0.7),
            .init(color: Color(hex: 0x2C5E4F), location: 1.0),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Layar berisi banyak konten: riwayat, detail, pengaturan.
    static let light = LinearGradient(
        stops: [
            .init(color: Color(hex: 0xFFFFFF), location: 0.0),
            .init(color: Color(hex: 0xF1F6F3), location: 0.5),
            .init(color: Color(hex: 0xCFE2D9), location: 1.0),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension View {
    /// Pasang gradien latar penuh layar di belakang konten.
    func screenBackground(_ gradient: LinearGradient) -> some View {
        background(gradient.ignoresSafeArea())
    }
}
