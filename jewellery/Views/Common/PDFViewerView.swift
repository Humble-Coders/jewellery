import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let pdfUrl: URL
    let orderId: String
    @Environment(\.dismiss) var dismiss
    @State private var pdfDocument: PDFDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var localFileUrl: URL?
    @State private var showShareSheet = false
    
    private let primaryBrown = Color(red: 146/255, green: 111/255, blue: 111/255)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading invoice...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text("Failed to load PDF")
                            .font(.system(size: 18, weight: .semibold))
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Retry") {
                            loadPDF()
                        }
                        .foregroundColor(primaryBrown)
                    }
                } else if let document = pdfDocument {
                    PDFKitView(document: document)
                }
            }
            .navigationTitle("Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 0.77, green: 0.62, blue: 0.62), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if pdfDocument != nil, let fileUrl = localFileUrl {
                        Menu {
                            Button {
                                savePDFToFiles(fileUrl: fileUrl)
                            } label: {
                                Label("Save to Files", systemImage: "folder")
                            }
                            Button {
                                showShareSheet = true
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let fileUrl = localFileUrl {
                    ShareSheet(items: [fileUrl])
                }
            }
            .onAppear {
                loadPDF()
            }
        }
    }
    
    private func loadPDF() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: pdfUrl)
                
                // Save to temp file for sharing
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "Invoice_\(orderId).pdf"
                let fileUrl = tempDir.appendingPathComponent(fileName)
                try data.write(to: fileUrl)
                
                if let document = PDFDocument(data: data) {
                    await MainActor.run {
                        self.pdfDocument = document
                        self.localFileUrl = fileUrl
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Could not parse PDF document"
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func savePDFToFiles(fileUrl: URL) {
        let documentPicker = UIDocumentPickerViewController(forExporting: [fileUrl], asCopy: true)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(documentPicker, animated: true)
        }
    }
}

// MARK: - PDFKit View Wrapper
struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
