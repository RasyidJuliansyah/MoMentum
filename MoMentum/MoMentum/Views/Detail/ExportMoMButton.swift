import SwiftUI
import UIKit

/// Tombol ikon ekspor MoM jadi file (PDF atau Markdown) di tab MoM (layar 08).
/// Belum ada di Figma; gaya mengikuti tombol Edit di sebelahnya.
/// File dibuat oleh `DocumentExportService` (sesi Logic) lalu dibuka di share sheet iOS.
struct ExportMoMButton: View {
    let document: MoMDocument

    @State private var exported: ExportedFile?
    @State private var failed = false

    var body: some View {
        Menu {
            Button("PDF", systemImage: "doc.richtext") { export(.pdf) }
            Button("Markdown (.md)", systemImage: "doc.plaintext") { export(.markdown) }
        } label: {
            Image(systemName: "arrow.down.doc")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MColor.n900)
                .frame(width: 36, height: 36)
                .background(MColor.n0, in: .circle)
                .overlay(Circle().strokeBorder(MColor.n200))
        }
        .accessibilityLabel("Ekspor MoM")
        .accessibilityHint("Simpan atau kirim MoM sebagai file PDF atau Markdown")
        .sheet(item: $exported) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
        .alert("File MoM gagal dibuat", isPresented: $failed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Coba lagi. Kalau masih gagal, salin teks MoM lewat tombol Salin teks.")
        }
    }

    private enum Format {
        case pdf
        case markdown
    }

    private func export(_ format: Format) {
        do {
            let url = switch format {
            case .pdf: try DocumentExportService.exportPDF(document)
            case .markdown: try DocumentExportService.exportMarkdown(document)
            }
            exported = ExportedFile(url: url)
        } catch {
            failed = true
        }
    }
}

private struct ExportedFile: Identifiable {
    let url: URL
    var id: URL { url }
}

/// Share sheet iOS untuk file. `ShareLink` butuh URL sejak awal, padahal file baru dibuat setelah
/// format dipilih, jadi dipakai `UIActivityViewController`.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
