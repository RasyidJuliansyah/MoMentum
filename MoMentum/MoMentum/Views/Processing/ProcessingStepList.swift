import SwiftUI

/// Daftar lima langkah proses di layar 05. Langkah yang berjalan disorot biru.
struct ProcessingStepList: View {
    let steps: [ProcessingContent.Step]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(steps) { step in
                HStack(spacing: MSpace.sm) {
                    icon(for: step.state)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.subheadline.weight(step.state == .pending ? .regular : .semibold))
                            .foregroundStyle(step.state == .pending ? MColor.n400 : MColor.n900)
                        if let subtitle = step.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(step.state == .current ? MColor.info : MColor.n600)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .background(step.state == .current ? MColor.infoBg : .clear, in: .rect(cornerRadius: 14))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel([step.title, step.subtitle, spokenState(step.state)].compactMap { $0 }.joined(separator: ", "))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MColor.n0.opacity(0.9), in: .rect(cornerRadius: 22))
        .shadow(color: MColor.brand900.opacity(0.06), radius: 12, y: 4)
    }

    private func icon(for state: ProcessingContent.StepState) -> some View {
        let symbol: String?
        let fill: Color
        switch state {
        case .done: (symbol, fill) = ("checkmark", MColor.brand700)
        case .current: (symbol, fill) = ("arrow.triangle.2.circlepath", MColor.info)
        case .failed: (symbol, fill) = ("xmark", MColor.danger)
        case .pending: (symbol, fill) = (nil, MColor.n0)
        }
        return ZStack {
            Circle().fill(fill)
            if state == .pending {
                Circle().strokeBorder(MColor.n200, lineWidth: 1.5)
            }
            if let symbol {
                Image(systemName: symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MColor.n0)
            }
        }
        .frame(width: 28, height: 28)
    }

    private func spokenState(_ state: ProcessingContent.StepState) -> String {
        switch state {
        case .done: "selesai"
        case .current: "sedang berjalan"
        case .pending: "menunggu"
        case .failed: "gagal"
        }
    }
}

#Preview {
    ProcessingStepList(steps: ProcessingContent.previewProcessing.steps)
        .padding()
        .screenBackground(MBackground.light)
}
