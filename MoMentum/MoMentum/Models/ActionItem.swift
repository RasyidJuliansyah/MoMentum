import Foundation
import SwiftData

@Model
final class ActionItem {
    var task: String
    var pic: String        // nama speaker, atau "PIC belum jelas" bila tidak disebut
    var dueDate: String?   // teks bebas, LLM tidak diminta menebak tanggal pasti
    // Field yang ditambahkan setelah rilis pertama WAJIB punya nilai bawaan di deklarasi, supaya
    // SwiftData bisa memigrasi database lama di iPhone. Tanpa itu app crash saat dibuka.
    /// Urutan tampil (layar 06), sesuai urutan output LLM — relasi SwiftData tidak menjaga urutan.
    var order: Int = 0
    /// Status selesai, dicentang user (layar 06). Default belum selesai.
    var isDone: Bool = false

    var meeting: Meeting?

    init(task: String, pic: String, dueDate: String? = nil, order: Int = 0) {
        self.task = task
        self.pic = pic
        self.dueDate = dueDate
        self.order = order
        self.isDone = false
    }
}
