import Foundation
import Combine

@MainActor
final class DocumentPreviewViewModel: ObservableObject {

    // MARK: - Dependencies

    private let router: DocumentsRouterProtocol
    private let pdfGenerator: PDFGenerator
    private let htmlRenderer: DocumentHTMLRenderer

    // MARK: - Input Data

    let document: BusinessDocument

    // MARK: - UI State

    @Published private(set) var isGeneratingPDF = false
    @Published private(set) var pdfURL: URL?
    @Published private(set) var errorMessage: String?
    @Published var isShareSheetPresented = false

    // MARK: - Derived UI

    var renderedHTML: String {
        (try? htmlRenderer.render(document: document)) ?? fallbackHTML
    }

    var buyerDisplayName: String {
        document.buyer.displayName.isEmpty ? "Покупатель не указан" : document.buyer.displayName
    }

    var buyerTaxID: String {
        document.buyer.taxID
    }

    var hasBuyerTaxID: Bool {
        !buyerTaxID.isEmpty
    }

    var amountText: String {
        let number = NSDecimalNumber(decimal: document.totals.total)
        let formatted = Self.amountFormatter.string(from: number) ?? number.stringValue
        return "\(formatted) \(document.currencyCode)"
    }

    var buttonTitle: String {
        isGeneratingPDF ? "Готовим PDF..." : "Отправить счет"
    }

    var isSendDisabled: Bool {
        isGeneratingPDF
    }

    // MARK: - Initialization

    init(
        document: BusinessDocument,
        router: DocumentsRouterProtocol,
        htmlRenderer: DocumentHTMLRenderer,
        pdfGenerator: PDFGenerator
    ) {
        self.document = document
        self.router = router
        self.htmlRenderer = htmlRenderer
        self.pdfGenerator = pdfGenerator
    }

    // MARK: - User Actions

    func didTapSend() async {
        guard !isGeneratingPDF else { return }

        errorMessage = nil
        isGeneratingPDF = true
        defer { isGeneratingPDF = false }

        do {
            let url = try await pdfGenerator.generatePDF(for: document)
            pdfURL = url
            isShareSheetPresented = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func didFinishSharing() {
        router.finishDocumentFlowAfterShare()
    }

    func didTapSignature() {
        // TODO: router.showSignature()
    }

    // MARK: - Formatting

    private static let amountFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.groupingSeparator = " "
        return f
    }()

    // MARK: - Fallback

    private let fallbackHTML: String = """
    <!DOCTYPE html>
    <html lang="ru">
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {
                margin: 0;
                padding: 0;
                background: #ffffff;
                font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                color: #1c1c1e;
            }
            .container {
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                height: 100vh;
                padding: 24px;
                box-sizing: border-box;
                text-align: center;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div>Не удалось отобразить документ</div>
        </div>
    </body>
    </html>
    """

}



