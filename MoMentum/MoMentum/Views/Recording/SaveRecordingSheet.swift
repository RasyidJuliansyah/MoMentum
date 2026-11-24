import SwiftUI

/// Layar 03 Simpan rekaman (Figma node 13:286). Muncul sebagai sheet setelah Stop.
struct SaveRecordingSheet: View {
    let initialDraft: MeetingContextDraft
    let duration: TimeInterval
    let levels: [Double]
    let onSave: (MeetingContextDraft, _ processNow: Bool) -> Void
    let onCancel: () -> Void

    @AppStorage(AppStorageKey.autoProcessWhenOnline) private var autoProcess = true
    @State private var draft = MeetingContextDraft()
    /// Tinggi isi sheet, supaya sheet setinggi isinya seperti di Figma (bisa ditarik ke .large).
    @State private var contentHeight: CGFloat = 640

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                playbackRow
                MeetingContextForm(draft: $draft)
                autoProcessToggle
                buttons
                    .padding(.top, MSpace.xs)
            }
            .padding(MSpace.lg)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .background(MColor.n0)
        .onAppear { draft = initialDraft }
        .presentationDetents([.height(contentHeight), .large])
        .presentationCornerRadius(MRadius.xl)
        .interactiveDismissDisabled()
    }

    private var header: some View {
        HStack {
            Text("Simpan rekaman")
                .font(.title2.weight(.semibold))
                .foregroundStyle(MColor.n900)
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MColor.n900)
                    .frame(width: 36, height: 36)
                    .background(MColor.n100, in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tutup")
        }
    }

    private var playbackRow: some View {
        HStack(spacing: MSpace.sm) {
            // TODO(UI): putar ulang rekaman setelah ada pemutar audio di Services.
            Button {} label: {
                Image(systemName: "play.fill")
                    .font(.body)
                    .foregroundStyle(MColor.n900)
                    .frame(width: 40, height: 40)
                    .background(MColor.n0, in: .circle)
                    .shadow(color: MColor.brand900.opacity(0.08), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(true)
            .accessibilityLabel("Putar rekaman")

            WaveformView(
                levels: Array(levels.suffix(36)).isEmpty ? WaveformView.decorativeLevels(count: 36) : Array(levels.suffix(36)),
                color: MColor.n900,
                barWidth: 2,
                spacing: 3
            )
            .frame(height: 32)

            HStack(spacing: 6) {
                Circle().fill(MColor.record).frame(width: 6, height: 6)
                Text(MFormat.clock(duration))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(MColor.n900)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Durasi \(MFormat.spokenDuration(duration))")
        }
        .padding(10)
        .background(MColor.n50, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(MColor.n200))
    }

    private var autoProcessToggle: some View {
        Toggle(isOn: $autoProcess) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Proses otomatis saat online")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MColor.n900)
                Text("Kalau offline, masuk antrean dulu")
                    .font(.caption)
                    .foregroundStyle(MColor.n600)
            }
        }
        .tint(MColor.brand700)
    }

    private var buttons: some View {
        HStack(spacing: 10) {
            Button("Batal", action: onCancel)
                .buttonStyle(.secondaryCapsule)
            Button {
                onSave(draft, autoProcess)
            } label: {
                if autoProcess {
                    Label("Simpan & proses", systemImage: "sparkles")
                } else {
                    Text("Simpan")
                }
            }
            .buttonStyle(.primaryCapsule)
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SaveRecordingSheet(
                initialDraft: MeetingContextDraft(
                    title: "Weekly Sync Product",
                    agenda: "Review sprint, roadmap Q1, isu SNBP",
                    terms: ["SNBP", "TKA", "LMS IFP"]
                ),
                duration: 7092,
                levels: WaveformView.decorativeLevels(count: 36, seed: 2),
                onSave: { _, _ in },
                onCancel: {}
            )
        }
}
