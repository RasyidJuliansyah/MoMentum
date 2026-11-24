import XCTest
@testable import MoMentum

final class DocumentExportServiceTests: XCTestCase {

    private func sampleDocument() -> MoMDocument {
        MoMDocument(
            title: "Review PRD Absen QR",
            dateText: "21 Nov 2026",
            timeText: "09.00–11.14 WIB",
            participants: ["RJ", "Dina"],
            topics: ["Alur absen"],
            decisions: ["Pakai QR statis"],
            actionItems: [ActionItemContent(task: "Siapkan draft", pic: "RJ", due: "Senin")]
        )
    }

    func testExportMarkdownWritesReadableFile() throws {
        let document = sampleDocument()
        let url = try DocumentExportService.exportMarkdown(document)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertEqual(url.pathExtension, "md")
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(content, document.markdown())
    }

    func testExportPDFProducesValidPDFFile() throws {
        let document = sampleDocument()
        let url = try DocumentExportService.exportPDF(document)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertEqual(url.pathExtension, "pdf")
        let data = try Data(contentsOf: url)
        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(data.prefix(5), Data("%PDF-".utf8))
    }

    func testExportFileNameSanitizesSlashAndColon() throws {
        var document = sampleDocument()
        document.title = "Sprint 3/4: Review"
        let mdURL = try DocumentExportService.exportMarkdown(document)
        defer { try? FileManager.default.removeItem(at: mdURL) }

        XCTAssertEqual(mdURL.lastPathComponent, "MoM - Sprint 3-4- Review.md")
    }
}
