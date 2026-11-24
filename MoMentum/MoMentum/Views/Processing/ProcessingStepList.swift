import SwiftUI

/// Daftar lima langkah proses di layar 05 dan 13.
struct ProcessingStepList: View {
    let steps: [ProcessingContent.Step]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(steps) { step in
                HStack(spacing: MSpace.sm) {
                    icon(for: step.state)
                        .frame(width: 24, height: 24)
                    Text(step.title)
                        .font(.subheadline.weight(step.state == .current || step.state == .failed ? .semibold : .regular))
                        .foregroundStyle(step.state == .pending ? MColor.n600 : MColor.n900)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(step.title), \(spokenState(step.state))")
            }
        }
        .padding(MSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MColor.n0.opacity(0.9), in: .rect(cornerRadius: 22))
        .shadow(color: MColor.brand900.opacity(0.06), radius: 12, y: 4)
    }

    @ViewBuilder
    private func icon(for state: ProcessingContent.StepState) -> some View {
        switch state {
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(MColor.success)
        case .current:
            ProgressView()
                .tint(MColor.brand700)
        case .pending:
            Image(systemName: "circle")
                .font(.title3)
                .foregroundStyle(MColor.n400)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(MColor.danger)
        }
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
    VStack {
        ProcessingStepList(steps: ProcessingContent.previewProcessing.steps)
        ProcessingStepList(steps: ProcessingContent.previewFailed.steps)
    }
    .padding()
    .screenBackground(MBackground.light)
}
