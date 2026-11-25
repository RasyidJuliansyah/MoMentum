import AVFAudio

/// Cek izin mikrofon sebelum merekam. Belum pernah ditanya → dialog iOS; sudah ditolak → `false`
/// (caller menampilkan jalan ke Pengaturan iOS, karena iOS tidak akan menampilkan dialognya lagi).
enum MicrophonePermission {
    static func ensureGranted() async -> Bool {
        #if DEBUG
        // UI test di simulator: dialog izin sistem akan menutupi layar.
        if UITestSupport.requestedSeed != nil { return true }
        #endif
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return true
        case .denied: return false
        default: return await AVAudioApplication.requestRecordPermission()
        }
    }
}
