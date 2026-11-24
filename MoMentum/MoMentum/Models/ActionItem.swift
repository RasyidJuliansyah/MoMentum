import Foundation
import SwiftData

@Model
final class ActionItem {
    var task: String
    var pic: String        // nama speaker, atau "PIC belum jelas" bila tidak disebut
    var dueDate: String?   // teks bebas, LLM tidak diminta menebak tanggal pasti

    var meeting: Meeting?

    init(task: String, pic: String, dueDate: String? = nil) {
        self.task = task
        self.pic = pic
        self.dueDate = dueDate
    }
}
