import SwiftUI

/// Layar 09 Pengaturan (Figma node 16:543).
struct SettingsView: View {
    @AppStorage(AppStorageKey.userName) private var userName = ""
    @AppStorage(AppStorageKey.monthlyCostLimitUSD) private var costLimit: Double = 0
    @AppStorage(AppStorageKey.audioRetentionDays) private var retentionDays = 30

    @State private var keys: [APIKeyKind: String] = [:]
    @State private var editingKind: APIKeyKind?
    @State private var deletingKind: APIKeyKind?
    @State private var isEditingLimit = false
    @State private var limitText = ""

    static let retentionOptions = [7, 30, 90, 0]

    static func retentionLabel(_ days: Int) -> String {
        days == 0 ? "Selamanya" : "\(days) hari"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader("API KEY · BYOK")
                    apiKeyCard
                    sectionHeader("BIAYA API")
                    costCard
                    sectionHeader("REKAMAN & PERANGKAT")
                    deviceCard
                    sectionHeader("PROFIL")
                    profileCard
                }
                .padding(.horizontal, MSpace.screen)
                .padding(.bottom, MSpace.lg)
            }
            .navigationTitle("Pengaturan")
            .screenBackground(MBackground.light)
            .onAppear(perform: reloadKeys)
            .sheet(item: $editingKind) { kind in
                KeyEditorSheet(kind: kind, onSaved: reloadKeys)
            }
            .confirmationDialog(
                "Hapus API key?",
                isPresented: Binding(get: { deletingKind != nil }, set: { if !$0 { deletingKind = nil } }),
                titleVisibility: .visible,
                presenting: deletingKind
            ) { kind in
                Button("Hapus key \(kind.title)", role: .destructive) {
                    APIKeyStore.delete(kind)
                    reloadKeys()
                }
            } message: { _ in
                Text("Meeting baru tidak bisa diproses sampai key dipasang lagi.")
            }
            .alert("Batas biaya bulanan", isPresented: $isEditingLimit) {
                TextField("Contoh: 10", text: $limitText)
                    .keyboardType(.decimalPad)
                Button("Batal", role: .cancel) {}
                Button("Simpan") {
                    costLimit = max(0, Double(limitText.replacingOccurrences(of: ",", with: ".")) ?? 0)
                }
            } message: {
                Text("Dalam dolar AS (USD), sesuai tagihan penyedia. Kosongkan atau isi 0 untuk tanpa batas.")
            }
        }
    }

    // MARK: Bagian

    private var apiKeyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(APIKeyKind.allCases) { kind in
                keyRow(kind)
            }
            Text("Key tidak ditanam di kode. Semua panggilan lewat provider adapter.")
                .font(.caption)
                .foregroundStyle(MColor.n600)
        }
        .settingsCard()
    }

    private func keyRow(_ kind: APIKeyKind) -> some View {
        let key = keys[kind]
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: MSpace.sm) {
                Image(systemName: kind.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MColor.n900)
                    .frame(width: 40, height: 40)
                    .background(MColor.brand50, in: .rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MColor.n900)
                    Text(kind.providerName)
                        .font(.caption)
                        .foregroundStyle(MColor.n600)
                }
                Spacer()
                Menu {
                    Button(key == nil ? "Pasang key" : "Ganti key", systemImage: "pencil") { editingKind = kind }
                    if key != nil {
                        Button("Hapus key", systemImage: "trash", role: .destructive) { deletingKind = kind }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(key == nil ? "Pasang" : "Ganti")
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(MColor.brand700)
                }
                .accessibilityLabel("\(key == nil ? "Pasang" : "Ganti") key \(kind.title)")
            }

            HStack(spacing: 10) {
                Image(systemName: "key")
                    .font(.footnote)
                    .foregroundStyle(MColor.n600)
                Text(key.map(KeyMask.masked) ?? "Belum dipasang")
                    .font(.subheadline)
                    .monospaced(key != nil)
                    .foregroundStyle(key == nil ? MColor.n400 : MColor.n900)
                    .lineLimit(1)
                Spacer()
                if key != nil {
                    Label("Keychain", systemImage: "lock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MColor.brand700)
                        .labelStyle(CompactLabelStyle())
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(MColor.n50, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(MColor.n200))
            .accessibilityElement(children: .combine)
        }
    }

    private var costCard: some View {
        VStack(alignment: .leading, spacing: MSpace.xs) {
            HStack {
                Text("Bulan ini")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MColor.n900)
                Spacer()
                Button {
                    limitText = costLimit > 0 ? MFormat.usd(costLimit).dropFirst().description : ""
                    isEditingLimit = true
                } label: {
                    Text(costLimit > 0 ? "Batas \(MFormat.usd(costLimit)) ›" : "Atur batas ›")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(MColor.brand700)
                }
            }
            // TODO(UI): tampilkan biaya bulan ini, durasi audio, dan bar terhadap batas setelah
            // pencatatan pemakaian tersedia (PLAN-logic.md L7).
            Text("Belum tercatat")
                .font(.title2.bold())
                .foregroundStyle(MColor.n400)
            Text("Biaya per bulan muncul setelah meeting pertama diproses.")
                .font(.caption)
                .foregroundStyle(MColor.n600)
        }
        .settingsCard()
    }

    private var deviceCard: some View {
        VStack(spacing: 0) {
            deviceRow("clock", "Durasi segmen") {
                Text("\(Int(RecordingConstants.segmentDuration / 60)) menit")
                    .foregroundStyle(MColor.n600)
            }
            Divider()
            deviceRow("doc.text", "Simpan audio setelah MoM jadi") {
                Picker("Simpan audio setelah MoM jadi", selection: $retentionDays) {
                    ForEach(Self.retentionOptions, id: \.self) { Text(Self.retentionLabel($0)).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(MColor.n600)
            }
            Divider()
            deviceRow("exclamationmark.triangle", "Profil instalasi") {
                profileBadge
            }
        }
        .padding(.horizontal, MSpace.md)
        .padding(.vertical, MSpace.xxs)
        .background(MColor.n0.opacity(0.9), in: .rect(cornerRadius: 22))
        .shadow(color: MColor.brand900.opacity(0.06), radius: 12, y: 4)
    }

    private func deviceRow(_ systemImage: String, _ title: String, @ViewBuilder trailing: () -> some View) -> some View {
        HStack(spacing: MSpace.sm) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(MColor.n900)
                .frame(width: 24)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MColor.n900)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: MSpace.xs)
            trailing()
                .font(.footnote)
                .fixedSize()
        }
        .frame(minHeight: 52)
    }

    @ViewBuilder
    private var profileBadge: some View {
        switch ProvisioningProfile.currentStatus() {
        case .unavailable:
            Text("Tidak ada (simulator)")
                .foregroundStyle(MColor.n600)
        case .expired:
            badge("Kedaluwarsa", MColor.danger, MColor.dangerBg)
        case .expiring(let days):
            badge(days == 0 ? "Habis hari ini" : "Habis \(days) hari", days <= 2 ? MColor.danger : MColor.warn, days <= 2 ? MColor.dangerBg : MColor.warnBg)
        case .valid(let until):
            Text("Sampai \(until.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "id_ID"))))")
                .foregroundStyle(MColor.n600)
        }
    }

    private func badge(_ text: String, _ foreground: Color, _ background: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(background, in: .capsule)
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: MSpace.xs) {
            Text("Nama di Beranda")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MColor.n900)
            TextField("Nama di Beranda", text: $userName, prompt: Text("Contoh: Rasyid"))
                .textInputAutocapitalization(.words)
                .fieldBackground()
            Text("Dipakai untuk sapaan dan inisial avatar. Kosongkan kalau tidak perlu.")
                .font(.caption)
                .foregroundStyle(MColor.n600)
        }
        .settingsCard()
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(MColor.n600)
            .padding(.top, MSpace.sm)
            .accessibilityAddTraits(.isHeader)
    }

    private func reloadKeys() {
        var loaded: [APIKeyKind: String] = [:]
        for kind in APIKeyKind.allCases {
            loaded[kind] = APIKeyStore.key(for: kind)
        }
        keys = loaded
    }
}

private extension View {
    func settingsCard() -> some View {
        padding(MSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MColor.n0.opacity(0.9), in: .rect(cornerRadius: 22))
            .shadow(color: MColor.brand900.opacity(0.06), radius: 12, y: 4)
    }
}

#Preview {
    SettingsView()
}
