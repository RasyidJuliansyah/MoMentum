import SwiftUI

/// Tampilan layar 02 Merekam (Figma node 13:157), termasuk state 14 (dijeda telepon)
/// dan 15 (ruang hampir penuh). Hanya menampilkan `snapshot`; aksi dikirim lewat closure.
struct RecordingScreen: View {
    let snapshot: RecordingSnapshot
    var onBack: () -> Void = {}
    var onMark: () -> Void = {}
    var onTogglePause: () -> Void = {}
    var onStop: () -> Void = {}

    private let waveformHalf = 28

    var body: some View {
        VStack(spacing: 0) {
            topBar
            noticeArea
                .padding(.top, MSpace.md)
            titleBlock
                .padding(.top, MSpace.lg)
            timerBlock
                .padding(.top, MSpace.lg)
            liveWaveform
                .padding(.top, MSpace.xl)
            if !snapshot.markers.isEmpty {
                MarkerChips(markers: snapshot.markers)
                    .padding(.top, MSpace.lg)
            }
            Spacer(minLength: MSpace.md)
            footer
        }
        .padding(.horizontal, MSpace.screen)
        .padding(.bottom, MSpace.xs)
        .screenBackground(MBackground.deep)
    }

    // MARK: Bagian layar

    private var topBar: some View {
        HStack {
            GlassIconButton(systemName: "chevron.left", accessibilityLabel: "Kembali", action: onBack)
            Spacer()
            BrandWordmark()
        }
    }

    @ViewBuilder
    private var noticeArea: some View {
        if snapshot.phase == .paused(.phoneCall) {
            StatusBanner(
                kind: .warning,
                systemImage: "pause.fill",
                title: "Dijeda karena telepon masuk",
                message: "Rekaman lanjut otomatis setelah panggilan selesai."
            )
        } else if snapshot.isStorageLow {
            StatusBanner(
                kind: .danger,
                systemImage: "exclamationmark.triangle.fill",
                title: storageTitle,
                message: storageMessage
            )
        } else {
            Label("Tetap merekam saat layar terkunci", systemImage: "lock")
                .font(.footnote)
                .foregroundStyle(MColor.n900)
                .padding(.horizontal, 14)
                .padding(.vertical, MSpace.xs)
                .glassEffect(.regular, in: .capsule)
        }
    }

    private var storageTitle: String {
        if let bytes = snapshot.storageRemainingBytes {
            return "Ruang penyimpanan tinggal \(MFormat.storage(bytes))"
        }
        return "Ruang penyimpanan hampir penuh"
    }

    private var storageMessage: String {
        if let hours = snapshot.storageRemainingHours, hours > 0 {
            return "Cukup untuk sekitar \(hours) jam lagi. Hapus audio lama di Pengaturan."
        }
        return "Cukup untuk kurang dari 1 jam lagi. Hapus audio lama di Pengaturan."
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text(snapshot.title)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(MColor.n900)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            if let agenda = snapshot.agenda {
                Text("Agenda: \(agenda)")
                    .font(.subheadline)
                    .foregroundStyle(MColor.n600)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
    }

    private var timerBlock: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(snapshot.isRecording ? MColor.record : MColor.warn)
                    .frame(width: 8, height: 8)
                    .phaseAnimator(snapshot.isRecording ? [1.0, 0.3] : [1.0]) { dot, opacity in
                        dot.opacity(opacity)
                    } animation: { _ in .easeInOut(duration: 0.8) }
                Text(snapshot.isRecording ? "Merekam" : "Dijeda")
                    .foregroundStyle(MColor.n900)
                Text("· Segmen \(snapshot.segmentNumber)")
                    .foregroundStyle(MColor.n600)
            }
            .font(.subheadline.weight(.medium))

            Text(MFormat.clock(snapshot.elapsed))
                .font(.system(size: 76, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(MColor.n900)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityLabel("Durasi \(MFormat.spokenDuration(snapshot.elapsed))")

            Text("Tersimpan otomatis tiap \(Int(RecordingConstants.segmentDuration / 60)) menit")
                .font(.footnote)
                .foregroundStyle(MColor.n600)
        }
        .accessibilityElement(children: .combine)
    }

    /// Kiri: level terbaru (penuh). Kanan: bar pudar sebagai sisa. Garis putih = posisi sekarang.
    private var liveWaveform: some View {
        let recent = Array(snapshot.levels.suffix(waveformHalf))
        let padded = Array(repeating: 0.06, count: waveformHalf - recent.count) + recent
        let tail = WaveformView.decorativeLevels(count: waveformHalf, seed: 7).map { $0 * 0.8 }
        return ZStack {
            WaveformView(levels: padded + tail, progress: 0.5, color: MColor.n0, barWidth: 3, spacing: 4)
                .frame(height: 104)
            Capsule()
                .fill(MColor.n0)
                .frame(width: 2, height: 128)
        }
        .opacity(snapshot.isRecording ? 1 : 0.6)
        .accessibilityHidden(true)
    }

    private var footer: some View {
        VStack(spacing: MSpace.sm) {
            if let hours = snapshot.storageRemainingHours {
                Text(snapshot.isStorageLow ? "Sisa ruang ± \(hours) jam" : "Disimpan lokal di iPhone · sisa ruang ± \(hours) jam")
                    .font(.caption)
                    .foregroundStyle(MColor.n0.opacity(0.8))
            }
            RecordingControls(
                isRecording: snapshot.isRecording,
                onMark: onMark,
                onTogglePause: onTogglePause,
                onStop: onStop
            )
        }
    }
}

#Preview("02 · Merekam") {
    RecordingScreen(snapshot: .preview)
}

#Preview("14 · Dijeda telepon") {
    var snapshot = RecordingSnapshot.preview
    snapshot.phase = .paused(.phoneCall)
    return RecordingScreen(snapshot: snapshot)
}

#Preview("15 · Ruang hampir penuh") {
    var snapshot = RecordingSnapshot.preview
    snapshot.isStorageLow = true
    snapshot.storageRemainingHours = 9
    snapshot.storageRemainingBytes = 1_200_000_000
    return RecordingScreen(snapshot: snapshot)
}
