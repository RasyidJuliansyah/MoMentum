import Foundation

/// Isian konteks meeting dari UI (judul, agenda, istilah khusus) sebelum disimpan ke model.
/// Field `agenda` dan istilah di `Meeting` menyusul dari sesi Logic (PLAN-logic.md L1.1).
struct MeetingContextDraft: Equatable {
    var title: String = ""
    var agenda: String = ""
    var terms: [String] = []

    /// Judul yang dipakai: isian user, atau judul otomatis dari tanggal kalau kosong.
    func resolvedTitle(at date: Date = .now) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultTitle(for: date) : trimmed
    }

    var trimmedAgenda: String? {
        let trimmed = agenda.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Tambah istilah. Spasi di ujung dibuang, istilah kosong atau ganda (tanpa beda huruf besar) diabaikan.
    @discardableResult
    mutating func addTerm(_ raw: String) -> Bool {
        let term = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty, !terms.contains(where: { $0.caseInsensitiveCompare(term) == .orderedSame }) else {
            return false
        }
        terms.append(term)
        return true
    }

    mutating func removeTerm(_ term: String) {
        terms.removeAll { $0 == term }
    }

    static func defaultTitle(for date: Date) -> String {
        let stamp = date.formatted(
            .dateTime.day().month(.abbreviated).hour().minute()
                .locale(Locale(identifier: "id_ID"))
        )
        return "Meeting \(stamp)"
    }
}
