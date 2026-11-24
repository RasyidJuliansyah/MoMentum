import SwiftData
import SwiftUI

/// Layar 01 Beranda (Figma node 13:29).
struct HomeView: View {
    var onOpenSettings: () -> Void = {}

    @Query(sort: \Meeting.createdAt, order: .reverse) private var meetings: [Meeting]
    @AppStorage(AppStorageKey.userName) private var userName = ""
    @State private var isRecording = false
    @State private var isEditingContext = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                greeting
                    .padding(.top, 28)
                recordSection
                    .padding(.top, 40)
                WeeklyActivityCard(stats: WeeklyStats(meetings: meetings))
                    .padding(.top, 48)
            }
            .padding(.horizontal, MSpace.screen)
            .padding(.bottom, MSpace.lg)
        }
        .scrollBounceBehavior(.basedOnSize)
        .screenBackground(MBackground.deep)
        .fullScreenCover(isPresented: $isRecording) {
            RecordingView()
        }
        .sheet(isPresented: $isEditingContext) {
            // TODO(UI): ganti dengan form konteks meeting (judul, agenda, istilah) saat layar 03 dibangun.
            ContentUnavailableView("Konteks meeting", systemImage: "tag", description: Text("Form judul, agenda, dan istilah menyusul."))
                .presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack(spacing: MSpace.xs) {
            BrandWordmark()
            Spacer()
            // TODO(UI): belum ada requirement notifikasi di PRD. Tombol dipasang sesuai desain, aksinya menyusul.
            GlassIconButton(systemName: "bell", accessibilityLabel: "Notifikasi") {}
            avatar
        }
    }

    private var avatar: some View {
        Button(action: onOpenSettings) {
            Group {
                if userName.isEmpty {
                    Image(systemName: "person.fill")
                } else {
                    Text(Greeting.initials(of: userName))
                }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(MColor.brand700)
            .frame(width: 44, height: 44)
            .background(MColor.brand100, in: .circle)
            .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Buka pengaturan")
    }

    private var greeting: some View {
        TimelineView(.everyMinute) { context in
            let text = Greeting.text(for: context.date)
            VStack(alignment: .leading, spacing: 2) {
                if userName.isEmpty {
                    Text(text)
                        .font(.largeTitle.bold())
                        .foregroundStyle(MColor.n900)
                } else {
                    Text("\(text),")
                        .font(.callout)
                        .foregroundStyle(MColor.n600)
                    Text(userName)
                        .font(.largeTitle.bold())
                        .foregroundStyle(MColor.n900)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    private var recordSection: some View {
        VStack(spacing: MSpace.md) {
            HStack(spacing: MSpace.xs) {
                WaveformView(levels: WaveformView.decorativeLevels(count: 14))
                    .frame(height: 64)
                RecordButton { isRecording = true }
                WaveformView(levels: WaveformView.decorativeLevels(count: 14, seed: 5))
                    .frame(height: 64)
            }

            Text("Ketuk untuk mulai merekam")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MColor.n900)

            Button {
                isEditingContext = true
            } label: {
                Label("Isi judul, agenda & istilah dulu", systemImage: "plus")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(MColor.brand700)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
    }
}

#Preview(traits: .sampleData) {
    HomeView()
}
