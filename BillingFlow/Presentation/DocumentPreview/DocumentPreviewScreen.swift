import SwiftUI

struct DocumentPreviewScreen: View {

    // MARK: - ViewModel

    @ObservedObject var viewModel: DocumentPreviewViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            previewContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomPanel
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $viewModel.isShareSheetPresented) {
            if let url = viewModel.pdfURL {
                ShareSheet(
                    activityItems: [url],
                    onComplete: {
                        viewModel.didFinishSharing()
                    }
                )
            }
        }
    }

    // MARK: - Preview Content

    private var previewContent: some View {
        DocumentPreviewWebView(html: viewModel.renderedHTML)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 6)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Color(.secondarySystemBackground))
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 8) {
            summaryBlock
            signatureRow
            sendButtonBlock
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }

    // MARK: - Summary UI

    private var summaryBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.amountText)
                    .font(.system(size: 27, weight: .bold, design: .rounded))

                Text("НДС не применяется")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.buyerDisplayName)
                    .font(.subheadline.weight(.semibold))

                if viewModel.hasBuyerTaxID {
                    Text("ИНН: \(viewModel.buyerTaxID)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Signature Action

    private var signatureRow: some View {
        Button {
            viewModel.didTapSignature()
        } label: {
            HStack {
                Image(systemName: "signature")
                Text("Подпись и печать")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Send Button

    private var sendButtonBlock: some View {
        VStack(alignment: .leading, spacing: 6) {

            if let error = viewModel.errorMessage, !error.isEmpty {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await viewModel.didTapSend() }
            } label: {
                HStack {
                    if viewModel.isGeneratingPDF {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                    }

                    Text(viewModel.buttonTitle)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSendDisabled)
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {

    let activityItems: [Any]
    let onComplete: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        vc.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onComplete()
            }
        }

        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


// MARK: - Preview

#Preview {
    NavigationStack {
        DocumentPreviewScreen(
            viewModel: DocumentPreviewViewModel(
                document: BusinessDocument(
                    type: .invoice,
                    number: "INV-2026-001",
                    date: Date(),
                    seller: DocumentParty(
                        displayName: "ООО BillingFlow Studio",
                        taxID: "6678123456",
                        registrationNumber: "667801001",
                        address: "г. Москва, ул. Горького, 12",
                        bankName: "АО Т-Банк",
                        bankAccount: "40702810900000000001",
                        bankCode: "044525974",
                        contactName: "Иван Иванов",
                        phone: "+7 912 000-00-00",
                        email: "finance@billingflow.app"
                    ),
                    buyer: DocumentParty(
                        displayName: "ООО Альфа",
                        taxID: "7701234567",
                        registrationNumber: "667801001",
                        address: "г. Москва, ул. Горького, 12",
                        bankName: "АО Т-Банк",
                        bankAccount: "40702810900000000001",
                        bankCode: "044525974",
                        contactName: "Иван Иванов",
                        phone: "+7 999 123-45-67",
                        email: "pay@alfa.ru"
                    ),
                    items: [
                        DocumentItem(
                            title: "Разработка интерфейса",
                            quantity: 1,
                            unit: "услуга",
                            price: 45_000
                        ),
                        DocumentItem(
                            title: "Подготовка PDF-документа",
                            quantity: 2,
                            unit: "час",
                            price: 3_500
                        )
                    ],
                    notes: "Оплата в течение 5 рабочих дней.",
                    currencyCode: "RUB",
                    status: .ready
                ),
                router: PreviewDocumentsRouter(),
                htmlRenderer: DocumentHTMLRenderer(),
                pdfGenerator: PDFGenerator()
            )
        )
    }
}

private final class PreviewDocumentsRouter: DocumentsRouterProtocol {
    func showCreateDocument(type: DocumentType) { }
    func showEditDocument(document: BusinessDocument) { }
    func showPreview(document: BusinessDocument) { }
    func finishDocumentFlowAfterShare() { }
    func dismiss() { }
    func pop() { }
}
