import Foundation
import UserNotifications

/// Notifikasi lokal "MoM siap" (D9, requirement S). Izin diminta lazy saat pertama kali dipakai
/// (`MeetingProcessor` memanggil `notify` setelah langkah `summarizing` selesai), bukan di
/// onboarding — sesuai PRD: "minta izin notifikasi saat pertama kali dipakai proses di background".
enum MeetingNotifier {
    /// `identifier` disetel ke string representasi `persistentModelID` meeting, supaya ketuk
    /// notifikasi bisa membuka meeting itu (UI membaca lewat `UNUserNotificationCenterDelegate`,
    /// belum diimplementasikan di sesi Logic — lihat handover.md 3a).
    static func notifyMoMReady(meetingTitle: String, identifier: String) async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "MoM siap"
        content.body = "Ringkasan \"\(meetingTitle)\" sudah selesai dibuat."
        content.userInfo = ["meetingID": identifier]

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        try? await center.add(request)
    }
}
