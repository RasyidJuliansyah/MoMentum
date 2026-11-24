import SwiftUI

/// Tampilan layar 05 Memproses (Figma node 14:374) dan 13 Proses gagal (node 18:598).
struct ProcessingScreen: View {
    let content: ProcessingContent
    var onRetry: () -> Void = {}
    var onProcessNow: () -> Void = {}
    var onCheckAPIKey: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if content.isFailed {
                    failedBody
                } else {
                    progressBody
                }
                note
            }
            .padding(.horizontal, MSpace.screen)
            .padding(.bottom, MSpace.lg)
        }
        .safeAreaInset(edge: .bottom) {
            actions
                .padding(.horizontal, MSpace.screen)
                .padding(.bottom, MSpace.xs)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StatusBadge(status: content.status)
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .screenBackground(MBackground.light)
    }

    // MARK: 05 Memproses

    private var progressBody: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(content.title)
                    .font(.title2.bold())
                    .foregroundStyle(MColor.n900)
                    .multilineTextAlignment(.center)
                Text(content.meta)
                    .font(.footnote)
                    .foregroundStyle(MColor.n600)
            }

            ZStack {
                Circle()
                    .fill(MColor.n0.opacity(0.55))
                    .frame(width: 200, height: 200)
                    .shadow(color: MColor.brand900.opacity(0.06), radius: 20, y: 8)
                ProgressRing(progress: content.progress)
                    .frame(width: 168, height: 168)
                VStack(spacing: 2) {
                    if let percent = content.percentText {
                        Text(percent)
                            .font(.system(size: 44, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(MColor.n900)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.title.weight(.semibold))
                            .foregroundStyle(MColor.brand700)
                    }
                    Text(content.stepCounterText ?? content.status.label)
                        .font(.footnote)
                        .foregroundStyle(MColor.n600)
                }
                .accessibilityHidden(true)
            }

            ProcessingStepList(steps: content.steps)
        }
    }

    // MARK: 13 Proses gagal

    private var failedBody: some View {
        VStack(alignment: .leading, spacing: MSpace.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title)
                    .font(.title.bold())
                    .foregroundStyle(MColor.n900)
                Text(content.meta)
                    .font(.footnote)
                    .foregroundStyle(MColor.n600)
            }

            errorCard
            ProcessingStepList(steps: content.steps)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var errorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MColor.n0)
                    .frame(width: 28, height: 28)
                    .background(MColor.danger, in: .circle)
                Text(content.errorTitle ?? "Proses gagal")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(MColor.danger)
            }
            if let message = content.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(MColor.n900)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(MSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MColor.dangerBg, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    // MARK: Catatan dan tombol

    @ViewBuilder
    private var note: some View {
        switch content.status {
        case .failed:
            NoteBox(systemImage: "checkmark", text: content.retryNote)
        case .queued:
            NoteBox(systemImage: "wifi.slash", text: "Menunggu internet. Meeting ini diproses otomatis begitu iPhone online.")
        case .recorded:
            NoteBox(systemImage: "tray", text: "Belum diproses. Ketuk Proses sekarang untuk mulai.")
        case .processing:
            // PRD: "Proses di background" dan "Notifikasi MoM siap" (PLAN-logic D9, L6.2).
            NoteBox(systemImage: "bell", text: "App boleh ditutup. Proses tetap jalan dan kamu dapat notifikasi saat MoM siap.")
        case .done:
            EmptyView()
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch content.status {
        case .failed:
            HStack(spacing: 10) {
                Button(action: onCheckAPIKey) {
                    Label("Cek API key", systemImage: "key")
                }
                .buttonStyle(.secondaryCapsule)
                Button(action: onRetry) {
                    Label("Coba lagi", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.primaryCapsule)
            }
        case .recorded:
            Button(action: onProcessNow) {
                Label("Proses sekarang", systemImage: "sparkles")
            }
            .buttonStyle(.primaryCapsule)
        case .queued, .processing, .done:
            EmptyView()
        }
    }
}

#Preview("05 · Memproses") {
    NavigationStack {
        ProcessingScreen(content: .previewProcessing)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("13 · Proses gagal") {
    NavigationStack {
        ProcessingScreen(content: .previewFailed)
            .navigationBarTitleDisplayMode(.inline)
    }
}
