import SwiftUI

/// Tampilan layar 05 Memproses (Figma node 14:374) dan 13 Proses gagal (node 18:598).
/// Dibangun dari spesifikasi design-handoff.md; cocokkan ulang ke Figma setelah akses desain pulih.
struct ProcessingScreen: View {
    let content: ProcessingContent
    var onRetry: () -> Void = {}
    var onProcessNow: () -> Void = {}
    var onCheckAPIKey: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: MSpace.lg) {
                header
                if content.isFailed {
                    failureHero
                } else {
                    progressHero
                }
                ProcessingStepList(steps: content.steps)
                notice
            }
            .padding(.horizontal, MSpace.screen)
            .padding(.bottom, MSpace.lg)
        }
        .safeAreaInset(edge: .bottom) {
            actions
                .padding(.horizontal, MSpace.screen)
                .padding(.bottom, MSpace.xs)
        }
        .screenBackground(MBackground.light)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(content.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(MColor.n900)
                .multilineTextAlignment(.center)
            Text(content.meta)
                .font(.footnote)
                .foregroundStyle(MColor.n600)
        }
        .padding(.top, MSpace.xs)
    }

    private var progressHero: some View {
        ZStack {
            ProgressRing(progress: content.progress)
            VStack(spacing: 2) {
                if let percent = content.percentText {
                    Text(percent)
                        .font(.largeTitle.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(MColor.n900)
                } else {
                    Image(systemName: "sparkles")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(MColor.brand700)
                }
                Text(content.status == .processing ? "Diproses" : content.status.label)
                    .font(.footnote)
                    .foregroundStyle(MColor.n600)
            }
            .accessibilityHidden(true)
        }
        .frame(width: 168, height: 168)
        .padding(.vertical, MSpace.xs)
    }

    private var failureHero: some View {
        VStack(spacing: MSpace.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(MColor.danger)
                .frame(width: 96, height: 96)
                .background(MColor.dangerBg, in: .circle)
                .accessibilityHidden(true)
            Text("Proses gagal")
                .font(.title3.weight(.semibold))
                .foregroundStyle(MColor.n900)
            Text(content.errorMessage ?? "Ada kendala saat memproses meeting ini.")
                .font(.subheadline)
                .foregroundStyle(MColor.n600)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var notice: some View {
        switch content.status {
        case .failed:
            StatusBanner(
                kind: .info,
                systemImage: "lock.fill",
                title: "Rekaman tetap aman",
                message: "Audio masih tersimpan di iPhone. Coba lagi tidak perlu merekam ulang."
            )
        case .queued:
            StatusBanner(
                kind: .warning,
                systemImage: "wifi.slash",
                title: "Menunggu internet",
                message: "Meeting ini diproses otomatis begitu iPhone online."
            )
        case .recorded:
            StatusBanner(
                kind: .info,
                systemImage: "tray",
                title: "Belum diproses",
                message: "Proses otomatis dimatikan saat menyimpan. Ketuk Proses sekarang untuk mulai."
            )
        case .processing:
            StatusBanner(
                kind: .info,
                systemImage: "info.circle.fill",
                title: "Biarkan app terbuka",
                message: "Kalau app ditutup, proses lanjut saat app dibuka lagi."
            )
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
                    Label("Coba lagi", systemImage: "arrow.clockwise")
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
