import SwiftUI

/// Label dan warna status meeting untuk UI. Enum-nya milik sesi Logic (`Models/Meeting.swift`).
extension MeetingStatus {
    var label: String {
        switch self {
        case .recorded: "Direkam"
        case .queued: "Menunggu"
        case .processing: "Diproses"
        case .done: "Selesai"
        case .failed: "Gagal"
        }
    }

    var colors: (fg: Color, bg: Color) {
        switch self {
        case .recorded: (MColor.n600, MColor.neutralBg)
        case .queued: (MColor.warn, MColor.warnBg)
        case .processing: (MColor.info, MColor.infoBg)
        case .done: (MColor.success, MColor.successBg)
        case .failed: (MColor.danger, MColor.dangerBg)
        }
    }
}
