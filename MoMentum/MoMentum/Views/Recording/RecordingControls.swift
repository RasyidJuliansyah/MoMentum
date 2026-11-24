import SwiftUI

/// Tombol Tandai, Jeda/Lanjut, dan Stop di bawah layar Merekam.
struct RecordingControls: View {
    let isRecording: Bool
    let onMark: () -> Void
    let onTogglePause: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onMark) {
                Label("Tandai", systemImage: "flag")
            }
            .buttonStyle(.glassCapsule)
            .disabled(!isRecording)
            .accessibilityHint("Tandai momen penting supaya diprioritaskan di ringkasan")

            Button(action: onTogglePause) {
                if isRecording {
                    Label("Jeda", systemImage: "pause.fill")
                } else {
                    Label("Lanjut", systemImage: "play.fill")
                }
            }
            .buttonStyle(.glassCapsule)

            Button(action: onStop) {
                Label {
                    Text("Stop")
                } icon: {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(MColor.record)
                }
            }
            .buttonStyle(.lightCapsule)
        }
        .labelStyle(.titleAndIcon)
    }
}

/// Chip penanda momen, misalnya "⚑ 00:42:10".
struct MarkerChips: View {
    let markers: [TimeInterval]

    var body: some View {
        HStack(spacing: 10) {
            Text("Momen ditandai")
                .font(.footnote)
                .foregroundStyle(MColor.n0.opacity(0.85))
            ScrollView(.horizontal) {
                HStack(spacing: MSpace.xs) {
                    ForEach(markers, id: \.self) { marker in
                        Label(MFormat.clock(marker), systemImage: "flag")
                            .font(.footnote.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(MColor.n0)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(MColor.n0.opacity(0.12), in: .capsule)
                            .overlay(Capsule().strokeBorder(MColor.n0.opacity(0.5)))
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Momen ditandai: \(markers.map { MFormat.spokenDuration($0) }.joined(separator: ", "))")
    }
}

#Preview {
    VStack(spacing: 24) {
        MarkerChips(markers: [2530, 3933])
        RecordingControls(isRecording: true, onMark: {}, onTogglePause: {}, onStop: {})
        RecordingControls(isRecording: false, onMark: {}, onTogglePause: {}, onStop: {})
    }
    .padding()
    .background(MColor.brand700)
}
