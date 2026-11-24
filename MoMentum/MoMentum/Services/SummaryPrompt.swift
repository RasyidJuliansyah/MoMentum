import Foundation

/// Prompt Bahasa Indonesia untuk `SummaryProvider`, dipisah dari provider supaya mudah disetel
/// tanpa menyentuh kode jaringan (L5.2).
enum SummaryPrompt {
    /// System prompt: aturan PIC dan skema JSON yang diminta.
    static let system = """
    Kamu adalah asisten yang merangkum transkrip meeting kantor berbahasa Indonesia menjadi \
    ringkasan, action items, dan Minutes of Meeting (MoM).

    Aturan penting:
    - PIC (person in charge) tiap action item HARUS diambil dari nama speaker yang disebutkan \
    di transkrip. Kalau tidak jelas siapa yang bertanggung jawab, tulis persis "PIC belum jelas". \
    Jangan pernah menebak nama.
    - Tenggat (dueDate) ditulis apa adanya kalau disebut di transkrip (mis. "Jumat depan", \
    "akhir bulan"). Kalau tidak disebut, kosongkan (null). Jangan menebak tanggal pasti.
    - Bagian transkrip di sekitar "momen ditandai" (markerOffsetsMs) diberi prioritas lebih \
    tinggi saat menyusun ringkasan dan keputusan.
    - Istilah khusus yang diberikan adalah istilah domain/proyek yang mungkin muncul di transkrip; \
    pakai ejaan yang benar untuk istilah itu di output.
    - Balas HANYA dengan JSON valid sesuai skema berikut, tanpa teks lain di luar JSON:

    {
      "summaryText": "ringkasan 2-4 paragraf dalam Bahasa Indonesia",
      "actionItems": [
        {"task": "deskripsi tugas", "pic": "nama atau 'PIC belum jelas'", "dueDate": "teks bebas atau null"}
      ],
      "momMarkdown": "MoM lengkap dalam Markdown dengan bagian: Info Meeting, Peserta, Topik, Keputusan, Action Items"
    }
    """

    /// User prompt: konteks meeting + transkrip. Dipisah dari system prompt supaya mudah diuji
    /// (tes L5.4 memeriksa prompt berisi nama speaker dan penanda momen).
    static func user(for input: SummaryInput) -> String {
        var lines: [String] = []
        lines.append("Judul meeting: \(input.meetingTitle)")
        if let agenda = input.agenda, !agenda.isEmpty {
            lines.append("Agenda: \(agenda)")
        }
        if !input.glossaryTerms.isEmpty {
            lines.append("Istilah khusus: \(input.glossaryTerms.joined(separator: ", "))")
        }
        if !input.markerOffsetsMs.isEmpty {
            let marks = input.markerOffsetsMs.map { formatTimestamp($0) }.joined(separator: ", ")
            lines.append("Momen ditandai (waktu audio): \(marks)")
        }
        lines.append("")
        lines.append("Transkrip:")
        for line in input.transcript {
            lines.append("[\(formatTimestamp(line.startMs))] \(line.speakerName): \(line.text)")
        }
        return lines.joined(separator: "\n")
    }

    private static func formatTimestamp(_ ms: Int) -> String {
        let totalSeconds = ms / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
