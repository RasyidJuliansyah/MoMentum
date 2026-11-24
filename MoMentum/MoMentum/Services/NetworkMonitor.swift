import Foundation
import Network

/// Wrapper `NWPathMonitor` (framework bawaan, bukan dependency baru). Callback `NWPathMonitor`
/// berjalan di thread terpisah — ditandai `nonisolated` dan dikirim balik ke main lewat `Task`
/// supaya tidak melanggar isolasi `@MainActor` default project (lihat PLAN-logic.md bagian A).
@Observable
final class NetworkMonitor {
    private(set) var isConnected: Bool = true

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.momentum.networkmonitor")

    init() {
        monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor in
                self?.isConnected = connected
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
