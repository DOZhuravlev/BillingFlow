import Combine
import Foundation

@MainActor
final class DocumentPreviewViewModel: ObservableObject {

    // MARK: - Dependencies

    private weak var coordinator: DocumentsCoordinatorProtocol?
    private let pdfGenerator: PDFGenerator
    private let htmlRenderer: DocumentHTMLRenderer

    // MARK: - Input Data

    let document: BusinessDocument

    // MARK: - UI State

    @Published private(set) var isGeneratingPDF = false
    @Published private(set) var pdfURL: URL?
    @Published private(set) var errorMessage: String?
    @Published var isShareSheetPresented = false

    // MARK: - Initialization

    init(
        document: BusinessDocument,
        router: DocumentsCoordinatorProtocol,
        htmlRenderer: DocumentHTMLRenderer,
        pdfGenerator: PDFGenerator
    ) {
        self.document = document
        self.coordinator = router
        self.htmlRenderer = htmlRenderer
        self.pdfGenerator = pdfGenerator
    }
}

// MARK: - Display State

extension DocumentPreviewViewModel {
    var renderedHTML: String {
        (try? htmlRenderer.render(document: document)) ?? fallbackHTML
    }

    var documentTitle: String {
        let number = document.number.trimmingCharacters(in: .whitespacesAndNewlines)

        guard number.isEmpty == false else {
            return "\(document.type.displayName) без номера"
        }

        return "\(document.type.displayName) №\(number)"
    }

    var documentSubtitle: String {
        "\(document.type.displayName) от \(AppDateFormatter.documentDateText(document.date))"
    }

    var buyerDisplayName: String {
        let name = document.buyer.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Покупатель не указан" : name
    }

    var buyerTaxIDText: String? {
        let taxID = document.buyer.taxID.trimmingCharacters(in: .whitespacesAndNewlines)
        return taxID.isEmpty ? nil : "ИНН \(taxID)"
    }

    var totalText: String {
        CurrencyFormatter.amountText(
            document.totals.total,
            currencyCode: document.currencyCode
        )
    }

    var buttonTitle: String {
        isGeneratingPDF ? "Готовим..." : "Отправить"
    }

    var isSendDisabled: Bool {
        isGeneratingPDF
    }
}

// MARK: - User Actions

extension DocumentPreviewViewModel {
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
        coordinator?.finishDocumentFlowAfterShare()
    }

    func didTapSignature() {
        // TODO: router.showSignature()
    }
}

// MARK: - Fallback

private extension DocumentPreviewViewModel {
    var fallbackHTML: String {
        """
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
}
