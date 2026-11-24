import SwiftUI

/// Badge status meeting (Figma: Status Badge, node 5:144). Capsule, titik 6 pt + label.
struct StatusBadge: View {
    let status: MeetingStatus

    var body: some View {
        let colors = status.colors
        HStack(spacing: 6) {
            Circle()
                .fill(colors.fg)
                .frame(width: 6, height: 6)
            Text(status.label)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(colors.fg)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(colors.bg, in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Status: \(status.label)")
    }
}

#Preview {
    HStack {
        StatusBadge(status: .recorded)
        StatusBadge(status: .queued)
        StatusBadge(status: .processing)
        StatusBadge(status: .done)
        StatusBadge(status: .failed)
    }
    .padding()
}
