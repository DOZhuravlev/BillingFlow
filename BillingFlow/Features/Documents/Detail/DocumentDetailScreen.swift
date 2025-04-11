import SwiftUI

struct DocumentDetailScreen: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: DocumentDetailViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    heroSection
                    actionsSection
                    overviewSection
                    lineItemsSection
                    requisitesSection
                    notesSection
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppLayout.floatingTabBarBottomInset)
            }
            .scrollIndicators(.hidden)
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

    var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.documentTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(2)

            Text(viewModel.documentSubtitle)
                .font(AppFont.Text.caption)
                .foregroundStyle(.white.opacity(0.72))

            Text(viewModel.totalText)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

// MARK: - Actions

private extension DocumentDetailScreen {

    var actionsSection: some View {
        HStack(spacing: AppSpacing.sm) {
            actionButton(
                title: "Редактировать",
                systemImage: "pencil",
                style: .primary,
                action: viewModel.didTapEdit
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

// MARK: - Overview

private extension DocumentDetailScreen {

    var overviewSection: some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                sectionTitle("Детали счёта", iconName: "doc.text.magnifyingglass")

                VStack(spacing: 0) {
                    overviewRow("Покупатель", viewModel.document.buyer.displayName, fallback: "Не указан")
                    divider
                    overviewRow("Продавец", viewModel.document.seller.displayName, fallback: "Не указан")
                    divider
                    overviewRow("Дата", AppDateFormatter.documentDateText(viewModel.document.date))
                    divider
                    overviewRow("Тип", viewModel.document.type.displayName)
                    divider
                    overviewRow("Позиций", viewModel.itemCountText)
                }
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(.white.opacity(0.36))
                }
            }
        }
    }

    func overviewRow(
        _ title: String,
        _ value: String,
        fallback: String = "Не указано"
    ) -> some View {
        infoRow(
            title,
            value,
            fallback: fallback,
            valueWeight: .semibold
        )
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 11)
    }

    var divider: some View {
        Rectangle()
            .fill(.white.opacity(0.34))
            .frame(height: 1)
            .padding(.leading, AppSpacing.md)
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
        ScrollView(.horizontal, showsIndicators: false) {
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
                infoRow("Подытог", viewModel.subtotalText)
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
                sectionTitle("Реквизиты", iconName: "building.columns.fill")

                VStack(spacing: AppSpacing.md) {
                    partySummaryCard(title: "Продавец", party: viewModel.document.seller)
                    partySummaryCard(title: "Покупатель", party: viewModel.document.buyer)
                }
            }
        }
    }

    func partySummaryCard(title: String, party: DocumentParty) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColor.Text.primary)

            Text(nonEmpty(party.displayName, fallback: "Не указано"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.Text.primary)

            VStack(spacing: 8) {
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
    func showEditDocument(document: BusinessDocument) { }
    func showPreview(document: BusinessDocument) { }
    func finishDocumentFlowAfterShare() { }
    func dismiss() { }
    func pop() { }
}
