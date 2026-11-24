/// Kunci `@AppStorage` (UserDefaults) untuk preferensi UI. Bukan untuk rahasia: API key ada di Keychain.
enum AppStorageKey {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let userName = "userName"
    static let autoProcessWhenOnline = "autoProcessWhenOnline"
    /// Batas biaya API per bulan dalam USD; 0 = belum diatur (PLAN-logic D7).
    static let monthlyCostLimitUSD = "monthlyCostLimitUSD"
    /// Lama audio disimpan setelah MoM jadi, dalam hari; 0 = selamanya (PLAN-logic D5).
    static let audioRetentionDays = "audioRetentionDays"
}
