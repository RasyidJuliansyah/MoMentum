import SwiftUI

/// Ikon kecil + teks dengan jarak rapat, untuk baris meta dan badge kecil.
struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}
