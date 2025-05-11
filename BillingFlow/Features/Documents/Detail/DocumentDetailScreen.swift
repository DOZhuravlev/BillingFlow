import SwiftUI

struct DocumentDetailScreen: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: DocumentDetailViewModel

    // MARK: - State

    @State private var scrollOffset: CGFloat = .zero

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                navigationHeader
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.sm)
                    .zIndex(1)

                ScrollView {
                    ScrollOffsetObserver { offset in
                        scrollOffset = max(offset.y, 0)
                    }
                    .frame(width: 0, height: 0)

                    VStack(spacing: AppSpacing.md) {
                        heroSection
                        actionsSection
                        lineItemsSection
                        requisitesSection
                        notesSection
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppLayout.floatingTabBarBottomInset)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

// MARK: - Layout

private extension DocumentDetailScreen {

    var backgroundLayer: some View {
        AppColor.Brand.background
            .ignoresSafeArea()
    }
}

// MARK: - Hero

private extension DocumentDetailScreen {

    var navigationHeader: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Button(action: viewModel.didTapBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.16), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.24), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                Text(nonEmpty(viewModel.document.buyer.displayName, fallback: "Контрагент не указан"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)

                navigationSubtitle
            }
            .padding(.top, 1)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.18), value: headerCollapseProgress)
    }

    @ViewBuilder
    var navigationSubtitle: some View {
        let buyerSubtitle = partySubtitle(for: viewModel.document.buyer)

        ZStack(alignment: .leading) {
            if buyerSubtitle.isEmpty == false {
                Text(buyerSubtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(3)
                    .opacity(1 - headerCollapseProgress)
            }

            Text(viewModel.totalText)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.84))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .opacity(headerCollapseProgress)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: buyerSubtitle.isEmpty ? 18 : 34, alignment: .topLeading)
    }

    var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.documentTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white.opacity(0.86))
                        .lineLimit(2)

                    Text(viewModel.documentSubtitle)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(.white.opacity(0.64))
                }
                .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text("К оплате")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.64))

                    Text(viewModel.totalText)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .opacity(1 - headerCollapseProgress)
        .animation(.easeInOut(duration: 0.18), value: headerCollapseProgress)
    }

    var headerCollapseProgress: CGFloat {
        let distance: CGFloat = 80
        return min(max(scrollOffset / distance, 0), 1)
    }
}

// MARK: - Actions

private extension DocumentDetailScreen {

    var actionsSection: some View {
        VStack(spacing: AppSpacing.sm) {
            if viewModel.canEdit {
                actionButton(
                    title: "Редактировать",
                    systemImage: "pencil",
                    style: .primary,
                    action: viewModel.didTapEdit
                )
            }

            HStack(spacing: AppSpacing.sm) {
                actionButton(
                    title: "Скопировать",
                    systemImage: "doc.on.doc",
                    style: .secondary,
                    action: viewModel.didTapDuplicate
                )

                actionButton(
                    title: "Предпросмотр",
                    systemImage: "doc.richtext",
                    style: .secondary,
                    action: viewModel.didTapPreview
                )
            }
        }
    }
}

// MARK: - Line Items

private extension DocumentDetailScreen {

    var lineItemsSection: some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                sectionTitle("Позиции", iconName: "list.bullet.rectangle.fill")
                lineItemsTable

                totalsBlock
            }
        }
    }

    var lineItemsTable: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(spacing: 0) {
                lineItemsHeader

                if viewModel.document.items.isEmpty {
                    emptyLineItemsView
                } else {
                    ForEach(Array(viewModel.document.items.enumerated()), id: \.element.id) { index, item in
                        lineItemRow(item, index: index)

                        if item.id != viewModel.document.items.last?.id {
                            Rectangle()
                                .fill(.white.opacity(0.34))
                                .frame(height: 1)
                                .padding(.leading, AppSpacing.md)
                                .padding(.trailing, AppSpacing.md)
                        }
                    }
                }
            }
            .frame(width: lineItemsTableWidth)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(.white.opacity(0.36))
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
    }

    var lineItemsHeader: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("№")
                .frame(width: 28, alignment: .leading)

            Text("Наименование")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Кол-во")
                .frame(width: 54, alignment: .trailing)

            Text("Ед.")
                .frame(width: 44, alignment: .leading)

            Text("Цена")
                .frame(width: 82, alignment: .trailing)

            Text("Сумма")
                .frame(width: 92, alignment: .trailing)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(AppColor.Text.secondary)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 10)
        .background(.white.opacity(0.26))
    }

    var emptyLineItemsView: some View {
        Text("В документе пока нет позиций.")
            .font(AppFont.Text.caption)
            .foregroundStyle(AppColor.Text.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
    }

    func lineItemRow(_ item: DocumentItem, index: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
            Text("\(index + 1)")
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)
                .frame(width: 28, alignment: .leading)

            Text(item.title.isEmpty ? "Без названия" : item.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(decimalText(item.quantity))
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 54, alignment: .trailing)

            Text(item.unit)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)
                .lineLimit(1)
                .frame(width: 44, alignment: .leading)

            Text(CurrencyFormatter.amountText(item.price, currencyCode: viewModel.document.currencyCode))
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 82, alignment: .trailing)

            Text(CurrencyFormatter.amountText(item.amount, currencyCode: viewModel.document.currencyCode))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 92, alignment: .trailing)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 11)
    }

    var lineItemsTableWidth: CGFloat {
        560
    }

    var totalsBlock: some View {
        VStack(spacing: 10) {
            VStack(spacing: 10) {
                if viewModel.vatBreakdownLines.isEmpty {
                    infoRow("НДС", "Без НДС")
                } else {
                    ForEach(viewModel.vatBreakdownLines) { line in
                        infoRow(
                            "в т.ч. НДС \(decimalText(line.rate))%",
                            CurrencyFormatter.amountText(line.amount, currencyCode: viewModel.document.currencyCode)
                        )
                    }
                }

                infoRow("Всего", viewModel.totalText, valueWeight: .bold)
            }
            .padding(AppSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(AppColor.Brand.primary.opacity(0.10))
            }
        }
    }
}

// MARK: - Requisites & Notes

private extension DocumentDetailScreen {

    var requisitesSection: some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                sectionTitle("Реквизиты для оплаты", iconName: "building.columns.fill")

                partySummaryCard(party: viewModel.document.seller)
            }
        }
    }

    func partySummaryCard(party: DocumentParty) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(spacing: 8) {
                compactInfoRow("Полное", party.fullName)
                compactInfoRow("ИНН", party.taxID)
                compactInfoRow("Адрес", party.address)
                compactInfoRow("Банк", party.bankName)
                compactInfoRow("Счёт", party.bankAccount)
                compactInfoRow("БИК", party.bankCode)
                compactInfoRow("Контакт", party.contactName)
                compactInfoRow("Телефон", party.phone)
                compactInfoRow("Email", party.email)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(.white.opacity(0.36))
        }
    }

    @ViewBuilder
    func compactInfoRow(_ title: String, _ value: String) -> some View {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty == false {
            infoRow(title, trimmedValue, valueWeight: .medium)
        }
    }

    @ViewBuilder
    var notesSection: some View {
        if let notesText = viewModel.notesText {
            MaterialCard(cornerRadius: AppRadius.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    sectionTitle("Комментарий", iconName: "text.alignleft")

                    Text(notesText)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(AppColor.Text.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Components

private extension DocumentDetailScreen {

    enum ActionButtonStyle {
        case primary
        case secondary
    }

    func actionButton(
        title: String,
        systemImage: String,
        style: ActionButtonStyle,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppFont.Control.button)
                .foregroundStyle(style == .primary ? .white : AppColor.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(style == .primary ? AppColor.Brand.primary : .white.opacity(0.72))
                }
        }
        .buttonStyle(.plain)
    }

    func sectionTitle(_ title: String, iconName: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColor.Text.secondary)

            Text(title)
                .font(AppFont.Text.headline)
                .foregroundStyle(AppColor.Text.primary)
        }
    }

    func infoRow(
        _ title: String,
        _ value: String,
        fallback: String = "Не указано",
        valueWeight: Font.Weight = .semibold
    ) -> some View {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayValue = trimmedValue.isEmpty ? fallback : trimmedValue

        return HStack(alignment: .firstTextBaseline, spacing: AppSpacing.md) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)
                .frame(width: 84, alignment: .leading)

            Text(displayValue)
                .font(.system(size: 14, weight: valueWeight))
                .foregroundStyle(AppColor.Text.primary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    func decimalText(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        return number.stringValue
    }

    func nonEmpty(_ value: String, fallback: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? fallback : trimmedValue
    }

    func partySubtitle(for party: DocumentParty) -> String {
        [
            party.taxID.isEmpty ? nil : "ИНН \(party.taxID)",
            party.address.isEmpty ? nil : party.address
        ]
        .compactMap { $0 }
        .joined(separator: " · ")
    }
}

// MARK: - Preview

#Preview {
    DocumentDetailScreen(
        viewModel: DocumentDetailViewModel(
            document: BusinessDocument(
                type: .invoice,
                number: "INV-001",
                seller: DocumentParty(displayName: "ООО BillingFlow Studio", taxID: "7701234567"),
                buyer: DocumentParty(displayName: "ООО Альфа", taxID: "6678123456"),
                items: [
                    DocumentItem(title: "Разработка интерфейса", quantity: 1, unit: "услуга", price: 45_000),
                    DocumentItem(title: "Подготовка PDF-документа", quantity: 2, unit: "час", price: 3_500)
                ],
                notes: "Оплата в течение 5 рабочих дней."
            ),
            coordinator: PreviewDocumentDetailRouter()
        )
    )
}

private final class PreviewDocumentDetailRouter: DocumentsCoordinatorProtocol {
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
