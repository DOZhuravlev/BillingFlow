import Foundation
import WebKit


struct PDFGenerator {

    private let htmlRenderer: DocumentHTMLRenderer

    private let webViewFrame = CGRect(x: 0, y: 0, width: 794, height: 1123)
    private let pdfPageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
    private let pdfPageInsets = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
    private let preparedPageRange = NSRange(location: 0, length: 100)
    private let fallbackFileName = "document"

    init(htmlRenderer: DocumentHTMLRenderer = DocumentHTMLRenderer()) {
        self.htmlRenderer = htmlRenderer
    }

    @MainActor
    func generatePDF(for document: BusinessDocument) async throws -> URL {
        let html = try htmlRenderer.render(document: document)
        let webView = makeWebView()

        try await loadHTML(html, in: webView)

        let data = try makePDFData(from: webView)
        let fileURL = makeFileURL(for: document)

        try data.write(to: fileURL, options: .atomic)

        return fileURL
    }

    // MARK: - Private API

    @MainActor
    private func makeWebView() -> WKWebView {
        let webView = WKWebView(
            frame: webViewFrame,
            configuration: makeWebViewConfiguration()
        )
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    private func makeWebViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        return configuration
    }

    @MainActor
    private func loadHTML(_ html: String, in webView: WKWebView) async throws {
        let delegate = NavigationDelegateProxy()
        webView.navigationDelegate = delegate
        try await delegate.load(html: html, in: webView)
    }

    @MainActor
    private func makePDFData(from webView: WKWebView) throws -> Data {
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)

        let printableRect = pdfPageRect.inset(by: pdfPageInsets)

        renderer.setValue(pdfPageRect, forKey: "paperRect")
        renderer.setValue(printableRect, forKey: "printableRect")
        renderer.prepare(forDrawingPages: preparedPageRange)

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: pdfPageRect)

        return pdfRenderer.pdfData { context in
            for pageIndex in 0..<renderer.numberOfPages {
                context.beginPage()
                renderer.drawPage(at: pageIndex, in: context.pdfContextBounds)
            }
        }
    }

    private func makeFileURL(for document: BusinessDocument) -> URL {
        let fileNameComponent = sanitizedFileComponent(
            document.number.isEmpty ? fallbackFileName : document.number
        )

        let fileName = "\(document.type.rawValue)-\(fileNameComponent)-\(document.id.uuidString).pdf"

        return FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName, isDirectory: false)
    }

    private func sanitizedFileComponent(_ value: String) -> String {
        let invalidCharacters = CharacterSet.alphanumerics.inverted
        let components = value.components(separatedBy: invalidCharacters)
        let sanitized = components.joined(separator: "-")
        return sanitized.isEmpty ? fallbackFileName : sanitized
    }
}

// MARK: - Navigation Delegate

@MainActor
private final class NavigationDelegateProxy: NSObject, WKNavigationDelegate {

    private var continuation: CheckedContinuation<Void, Error>?

    func load(html: String, in webView: WKWebView) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        resume(with: .success(()))
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        resume(with: .failure(error))
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        resume(with: .failure(error))
    }

    private func resume(with result: Result<Void, Error>) {
        guard let continuation else { return }
        self.continuation = nil

        switch result {
        case .success:
            continuation.resume()
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}
