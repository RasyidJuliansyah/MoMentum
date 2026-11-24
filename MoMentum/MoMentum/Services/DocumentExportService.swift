import Foundation
import UIKit

enum DocumentExportError: Error {
    case renderFailed
}

/// Tulis `MoMDocument` ke file di `tmp` untuk dibagikan lewat `ShareLink(item: url)` (UI, layar 08).
/// File di `tmp` bukan tanggung jawab penghapusan di sini — iOS boleh bersihkan `tmp` kapan saja;
/// caller (UI) pakai lalu buang, tidak perlu persist.
///
/// ponytail: DOCX (OOXML asli) tidak diimplementasi — butuh zip+XML writer, tidak ada di
/// stdlib/UIKit, dan menambah dependency Swift Package butuh persetujuan (lihat aturan wilayah
/// Logic). Kalau nanti memang perlu, opsi: ZIPFoundation + XML template manual.
enum DocumentExportService {
    /// `.md` — tulis langsung string markdown yang sudah ada di `MoMDocument.markdown()`.
    static func exportMarkdown(_ document: MoMDocument) throws -> URL {
        let url = tempURL(title: document.title, ext: "md")
        try document.markdown().write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// `.pdf` — render `plainText()` apa adanya (bukan markdown) pakai `UIGraphicsPDFRenderer`
    /// native, A4, font sistem. Tidak ada styling kaya (bold/heading) — kalau nanti perlu,
    /// upgrade: parse markdown jadi `NSAttributedString` per baris sebelum digambar.
    static func exportPDF(_ document: MoMDocument) throws -> URL {
        let url = tempURL(title: document.title, ext: "pdf")
        let pageWidth: CGFloat = 595.2   // A4 @ 72dpi
        let pageHeight: CGFloat = 841.8
        let margin: CGFloat = 48
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let textRect = pageRect.insetBy(dx: margin, dy: margin)

        let attributed = NSAttributedString(
            string: document.plainText(),
            attributes: [.font: UIFont.systemFont(ofSize: 11)]
        )
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        do {
            try renderer.writePDF(to: url) { context in
                var rangeStart = 0
                let fullLength = attributed.length
                while rangeStart < fullLength {
                    context.beginPage()
                    let path = CGPath(rect: textRect, transform: nil)
                    let frame = CTFramesetterCreateFrame(
                        framesetter, CFRangeMake(rangeStart, 0), path, nil
                    )
                    let cgContext = context.cgContext
                    cgContext.textMatrix = .identity
                    cgContext.translateBy(x: 0, y: pageHeight)
                    cgContext.scaleBy(x: 1, y: -1)
                    CTFrameDraw(frame, cgContext)

                    let visibleRange = CTFrameGetVisibleStringRange(frame)
                    guard visibleRange.length > 0 else { break }
                    rangeStart += visibleRange.length
                }
            }
        } catch {
            throw DocumentExportError.renderFailed
        }
        return url
    }

    private static func tempURL(title: String, ext: String) -> URL {
        let safeTitle = title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let fileName = safeTitle.isEmpty ? "MoM" : "MoM - \(safeTitle)"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName).appendingPathExtension(ext)
    }
}
