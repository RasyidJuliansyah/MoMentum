import Foundation
import BackgroundTasks
#if canImport(UIKit)
import UIKit
#endif

/// D9: app ditutup setelah "Simpan & proses" ditekan, proses tetap lanjut.
/// - `beginBackgroundTask` memberi waktu singkat (biasanya puluhan detik) untuk menyelesaikan
///   langkah yang sedang berjalan saat app pindah ke background.
/// - `BGTaskScheduler` mendaftarkan kelanjutan proses (polling transkripsi, lalu ringkasan)
///   untuk dibangunkan iOS nanti — waktunya ditentukan iOS, tidak bisa dijamin (lihat PRD S
///   "Proses di background": tanpa backend/push, keterlambatan diterima).
enum BackgroundTaskCoordinator {
    /// Harus sama dengan key di `BGTaskSchedulerPermittedIdentifiers`, `Info.plist`.
    static let processingTaskIdentifier = "com.momentum.processing"

    /// Dipanggil sekali di `MoMentumApp.init` (sebelum scene muncul), sesuai dokumentasi Apple.
    static func registerBackgroundTask(handler: @escaping @Sendable () async -> Void) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: processingTaskIdentifier, using: nil) { task in
            let bgTask = task as! BGProcessingTask
            let work = Task {
                await handler()
                bgTask.setTaskCompleted(success: true)
            }
            bgTask.expirationHandler = {
                work.cancel()
            }
        }
    }

    /// Dipanggil `MeetingProcessor` saat ada meeting dengan status `.queued`/`.processing`
    /// dan app akan ke background, supaya iOS tahu ada kerjaan lanjutan.
    static func scheduleProcessingContinuation() {
        let request = BGProcessingTaskRequest(identifier: processingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        try? BGTaskScheduler.shared.submit(request)
    }

    #if canImport(UIKit)
    /// Membungkus satu langkah proses dengan `beginBackgroundTask`/`endBackgroundTask`, supaya
    /// langkah yang sedang berjalan (mis. upload) sempat selesai saat user menutup app.
    /// Build setting project default `@MainActor` (lihat PLAN-logic.md bagian A), jadi
    /// `UIApplication.shared` boleh diakses langsung tanpa `await` tambahan di sini.
    @MainActor
    static func withBackgroundTask<T>(_ body: () async throws -> T) async rethrows -> T {
        let application = UIApplication.shared
        var taskID: UIBackgroundTaskIdentifier = .invalid
        taskID = application.beginBackgroundTask(withName: "MeetingProcessing") {
            application.endBackgroundTask(taskID)
        }
        defer {
            if taskID != .invalid {
                application.endBackgroundTask(taskID)
            }
        }
        return try await body()
    }
    #else
    static func withBackgroundTask<T>(_ body: () async throws -> T) async rethrows -> T {
        try await body()
    }
    #endif
}
