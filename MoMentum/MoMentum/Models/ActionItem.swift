import Foundation
import SwiftData

@Model
final class ActionItem {
    var task: String
    var pic: String        // nama speaker, atau "PIC belum jelas" bila tidak disebut
    var dueDate: String?   // teks bebas, LLM tidak diminta menebak tanggal pasti
    /// Urutan tampil (layar 06), sesuai urutan output LLM — relasi SwiftData tidak menjaga urutan.
    var order: Int
    /// Status selesai, dicentang user (layar 06). Default belum selesai.
    var isDone: Bool

    var meeting: Meeting?

    init(task: String, pic: String, dueDate: String? = nil, order: Int = 0) {
        self.task = task
        self.pic = pic
        self.dueDate = dueDate
        self.order = order
        self.isDone = false
    }
}
