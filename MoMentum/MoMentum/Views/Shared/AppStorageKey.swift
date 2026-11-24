/// Kunci `@AppStorage` (UserDefaults) untuk preferensi UI. Bukan untuk rahasia: API key ada di Keychain.
enum AppStorageKey {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let userName = "userName"
    static let autoProcessWhenOnline = "autoProcessWhenOnline"
}
