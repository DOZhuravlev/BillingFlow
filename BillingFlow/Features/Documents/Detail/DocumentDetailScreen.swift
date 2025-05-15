import SwiftUI
import UIKit

struct DocumentDetailScreen: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: DocumentDetailViewModel

    // MARK: - State

    @State private var scrollOffset: CGFloat = .zero
    @State private var expandedLineItemIDs = Set<UUID>()
    @State private var isPaymentDetailsPresented = false
    @State private var copiedRequisiteID: String?

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
        .sheet(isPresented: $isPaymentDetailsPresented) {
            paymentDetailsSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
                Text(viewModel.documentTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

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
        ZStack(alignment: .leading) {
            Text(viewModel.documentSubtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(1)
                .opacity(1 - headerCollapseProgress)

            Text(viewModel.totalText)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white.opacity(0.84))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .opacity(headerCollapseProgress)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 18, alignment: .topLeading)
    }

    var heroSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
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

            VStack(alignment: .leading, spacing: 5) {
                Text("Контрагент")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.64))

                Text(nonEmpty(viewModel.document.buyer.displayName, fallback: "Контрагент не указан"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                let buyerSubtitle = partySubtitle(for: viewModel.document.buyer)
                if buyerSubtitle.isEmpty == false {
                    Text(buyerSubtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
                            .padding(.horizontal, AppSpacing.md)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(.white.opacity(0.36))
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
    }

    var lineItemsHeader: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("№")
                .frame(width: 20, alignment: .leading)

            Text("Наименование")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Кол-во")
                .frame(width: 58, alignment: .trailing)

            Text("Сумма")
                .frame(width: 88, alignment: .trailing)
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
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            Text("\(index + 1)")
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)
                .frame(width: 20, alignment: .leading)

            ExpandableLineItemTitle(
                title: item.title.isEmpty ? "Без названия" : item.title,
                isExpanded: expandedLineItemIDs.contains(item.id),
                onToggle: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        toggleLineItem(item.id)
                    }
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(quantityText(for: item))
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.primary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .frame(width: 58, alignment: .trailing)

            Text(CurrencyFormatter.amountText(item.amount, currencyCode: viewModel.document.currencyCode))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.64)
                .frame(width: 88, alignment: .trailing)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 11)
    }

    func quantityText(for item: DocumentItem) -> String {
        let unit = item.unit.trimmingCharacters(in: .whitespacesAndNewlines)
        return unit.isEmpty ? decimalText(item.quantity) : "\(decimalText(item.quantity))\n\(unit)"
    }

    func toggleLineItem(_ id: UUID) {
        if expandedLineItemIDs.contains(id) {
            expandedLineItemIDs.remove(id)
        } else {
            expandedLineItemIDs.insert(id)
        }
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
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text(nonEmpty(party.displayName, fallback: "Получатель не указан"))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColor.Text.primary)
                .fixedSize(horizontal: false, vertical: true)

            if party.bankAccount.isEmpty == false {
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("Расчетный счет")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColor.Text.secondary)

                        Spacer(minLength: AppSpacing.sm)

                        Button {
                            copyRequisite(party.bankAccount, id: "account")
                        } label: {
                            Image(systemName: copiedRequisiteID == "account" ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AppColor.Brand.primary)
                                .frame(width: 30, height: 30)
                                .background(AppColor.Brand.primary.opacity(0.10), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Скопировать расчетный счет")
                    }

                    Text(party.bankAccount)
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppColor.Text.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }

            if party.bankName.isEmpty == false {
                paymentInfoBlock(title: "Банк", value: party.bankName)
            }

            if party.bankCode.isEmpty == false {
                paymentInfoBlock(title: "БИК", value: party.bankCode)
            }

            HStack(spacing: AppSpacing.sm) {
                paymentActionButton(
                    title: copiedRequisiteID == "all" ? "Скопировано" : "Скопировать",
                    iconName: copiedRequisiteID == "all" ? "checkmark" : "doc.on.doc",
                    isPrimary: true
                ) {
                    copyRequisite(allRequisitesText(for: party), id: "all")
                }

                paymentActionButton(
                    title: "Все реквизиты",
                    iconName: "info.circle",
                    isPrimary: false
                ) {
                    isPaymentDetailsPresented = true
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func paymentInfoBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColor.Text.secondary)

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.Text.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func paymentActionButton(
        title: String,
        iconName: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: iconName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isPrimary ? .white : AppColor.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(isPrimary ? AppColor.Brand.primary : .black.opacity(0.05))
                }
        }
        .buttonStyle(.plain)
    }

    var paymentDetailsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Данные получателя")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black.opacity(0.9))

                    VStack(spacing: 10) {
                        paymentDetailRow(title: "Название", value: viewModel.document.seller.displayName)
                        paymentDetailRow(title: "Полное наименование", value: viewModel.document.seller.fullName)
                        paymentDetailRow(title: "ИНН", value: viewModel.document.seller.taxID)
                        paymentDetailRow(title: "КПП / ОГРН", value: viewModel.document.seller.registrationNumber)
                        paymentDetailRow(title: "Адрес", value: viewModel.document.seller.address)
                        paymentDetailRow(title: "Банк", value: viewModel.document.seller.bankName)
                        paymentDetailRow(title: "Расчетный счет", value: viewModel.document.seller.bankAccount)
                        paymentDetailRow(title: "БИК", value: viewModel.document.seller.bankCode)
                        paymentDetailRow(title: "Руководитель", value: viewModel.document.seller.contactName)
                        paymentDetailRow(title: "Телефон", value: viewModel.document.seller.phone)
                        paymentDetailRow(title: "Email", value: viewModel.document.seller.email)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Реквизиты для оплаты")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                paymentDetailsBottomAction
            }
        }
    }

    func paymentDetailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.black.opacity(0.52))

            Text(value.isEmpty ? "Не указано" : value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(value.isEmpty ? .black.opacity(0.38) : .black.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.black.opacity(0.035))
        }
    }

    var paymentDetailsBottomAction: some View {
        Button {
            isPaymentDetailsPresented = false
        } label: {
            Text("Готово")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppColor.Brand.primary)
                }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    func copyRequisite(_ value: String, id: String) {
        guard value.isEmpty == false else { return }

        UIPasteboard.general.string = value
        copiedRequisiteID = id

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if copiedRequisiteID == id {
                copiedRequisiteID = nil
            }
        }
    }

    func allRequisitesText(for party: DocumentParty) -> String {
        [
            requisiteLine(title: "Получатель", value: party.displayName),
            requisiteLine(title: "Полное наименование", value: party.fullName),
            requisiteLine(title: "ИНН", value: party.taxID),
            requisiteLine(title: "КПП / ОГРН", value: party.registrationNumber),
            requisiteLine(title: "Адрес", value: party.address),
            requisiteLine(title: "Банк", value: party.bankName),
            requisiteLine(title: "Расчетный счет", value: party.bankAccount),
            requisiteLine(title: "БИК", value: party.bankCode)
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }

    func requisiteLine(title: String, value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : "\(title): \(trimmedValue)"
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

// MARK: - Expandable Line Item

private struct ExpandableLineItemTitle: View {

    let title: String
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            HStack(alignment: .top, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.Text.primary)
                    .lineLimit(isExpanded ? nil : 1)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onToggle) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColor.Text.primary)
                        .frame(width: 24, height: 20)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isExpanded ? "Свернуть наименование" : "Показать наименование полностью")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
