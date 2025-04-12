import SwiftUI

struct DocumentPreviewScreen: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: DocumentPreviewViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: AppSpacing.md) {
                headerSection
                previewSection
                bottomPanel
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
        }
        .sheet(isPresented: $viewModel.isShareSheetPresented) {
            if let url = viewModel.pdfURL {
                ShareSheet(
                    activityItems: [url],
                    onComplete: viewModel.didFinishSharing
                )
            }
        }
    }
}

// MARK: - Layout

private extension DocumentPreviewScreen {

    var backgroundLayer: some View {
        AppColor.Brand.background
            .ignoresSafeArea()
    }
}

// MARK: - Header

private extension DocumentPreviewScreen {

    var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.documentTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(viewModel.documentSubtitle)
                .font(AppFont.Text.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

// MARK: - Preview

private extension DocumentPreviewScreen {

    var previewSection: some View {
        VStack(spacing: 0) {
            previewToolbar
            previewCanvas
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(.white.opacity(0.22))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .stroke(.white.opacity(0.32), lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 24, x: 0, y: 12)
    }

    var previewToolbar: some View {
        HStack(spacing: AppSpacing.sm) {
            Label("Предпросмотр", systemImage: "doc.richtext")
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.primary)

            Spacer()

            Text(viewModel.totalText)
                .font(AppFont.Number.smallAmount)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 10)
        .background(.white.opacity(0.78))
    }

    var previewCanvas: some View {
        DocumentPreviewWebView(html: viewModel.renderedHTML)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white.opacity(0.84))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.black.opacity(0.05))
                    .frame(height: 1)
            }
    }
}

// MARK: - Bottom Panel

private extension DocumentPreviewScreen {

    var bottomPanel: some View {
        MaterialCard(cornerRadius: AppRadius.lg, padding: AppSpacing.md) {
            VStack(spacing: AppSpacing.md) {
                summarySection
                actionsSection
                errorSection
            }
        }
    }

    var summarySection: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 6) {
                Text("К отправке")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)

                Text(viewModel.totalText)
                    .font(AppFont.Number.amount)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: AppSpacing.md)

            VStack(alignment: .trailing, spacing: 6) {
                Text(viewModel.buyerDisplayName)
                    .font(AppFont.Text.subheadline)
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)

                if let buyerTaxIDText = viewModel.buyerTaxIDText {
                    Text(buyerTaxIDText)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    var actionsSection: some View {
        HStack(spacing: AppSpacing.sm) {
            secondaryActionButton(
                title: "Подпись",
                systemImage: "signature",
                action: viewModel.didTapSignature
            )

            sendButton
        }
    }

    @ViewBuilder
    var errorSection: some View {
        if let errorMessage = viewModel.errorMessage, errorMessage.isEmpty == false {
            Text(errorMessage)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Status.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Components

private extension DocumentPreviewScreen {

    func secondaryActionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppFont.Control.button)
                .foregroundStyle(AppColor.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(.white.opacity(0.72))
                }
        }
        .buttonStyle(.plain)
    }

    var sendButton: some View {
        Button {
            Task { await viewModel.didTapSend() }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if viewModel.isGeneratingPDF {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                }

                Text(viewModel.buttonTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(AppFont.Control.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(viewModel.isSendDisabled ? AppColor.Brand.primary.opacity(0.55) : AppColor.Brand.primary)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSendDisabled)
    }
}

private struct ShareSheet: UIViewControllerRepresentable {

    let activityItems: [Any]
    let onComplete: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let viewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        viewController.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onComplete()
            }
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
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
                    currencyCode: "RUB"
                ),
                router: PreviewDocumentsRouter(),
                htmlRenderer: DocumentHTMLRenderer(),
                pdfGenerator: PDFGenerator()
            )
        )
    }
}

private final class PreviewDocumentsRouter: DocumentsCoordinatorProtocol {
    func start() { }
    func showDetail(document: BusinessDocument) { }
    func showCreateDocument(type: DocumentType) { }
    func showDuplicateDocument(document: BusinessDocument) { }
    func showEditDocument(document: BusinessDocument) { }
    func showPreview(document: BusinessDocument) { }
    func finishDocumentFlowAfterShare() { }
    func dismiss() { }
    func pop() { }
}
