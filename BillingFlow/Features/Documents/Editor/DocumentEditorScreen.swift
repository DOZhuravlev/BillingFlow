import SwiftUI

struct DocumentEditorScreen: View {

    // MARK: - Dependencies

    @ObservedObject var viewModel: DocumentEditorViewModel

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerSection
                    documentMetaSection
                    sellerSection
                    buyerSection
                    itemsSection
                    totalsSection
                    notesSection
                    saveActionSection
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

private extension DocumentEditorScreen {

    var backgroundLayer: some View {
        AppColor.Brand.background
            .ignoresSafeArea()
    }
}

// MARK: - Header

private extension DocumentEditorScreen {

    var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                documentTypeIcon

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.navigationTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text(documentSubtitle)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()
            }
        }
    }

    var documentTypeIcon: some View {
        Image(systemName: iconName(for: viewModel.draft.type))
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 50, height: 50)
            .background {
                Circle()
                    .fill(.white.opacity(0.16))
            }
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.34), lineWidth: 1)
            }
    }

    var documentSubtitle: String {
        viewModel.isEditing ? "Измените данные документа и сохраните новую версию." : "Заполните реквизиты, позиции и подготовьте документ."
    }
}

// MARK: - Document Meta

private extension DocumentEditorScreen {

    var documentMetaSection: some View {
        editorSection(title: "Документ", iconName: "doc.text.fill") {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    typeBadge

                    Spacer()
                }

                editorTextField(
                    title: "Номер",
                    placeholder: "Например, INV-001",
                    text: documentNumberBinding
                )

                editorTextField(
                    title: "Валюта",
                    placeholder: "RUB",
                    text: currencyCodeBinding
                )

                DatePicker(
                    "Дата",
                    selection: documentDateBinding,
                    displayedComponents: .date
                )
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.primary)
                .datePickerStyle(.compact)
            }
        }
    }

    var typeBadge: some View {
        Label(viewModel.draft.type.displayName, systemImage: iconName(for: viewModel.draft.type))
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppColor.Brand.primary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background {
                Capsule()
                    .fill(AppColor.Brand.primary.opacity(0.10))
            }
    }
}

// MARK: - Counterparties

private extension DocumentEditorScreen {

    var sellerSection: some View {
        partySection(
            title: "Продавец",
            iconName: "building.2.fill",
            party: viewModel.draft.seller,
            update: viewModel.updateSeller
        )
    }

    var buyerSection: some View {
        partySection(
            title: "Покупатель",
            iconName: "person.crop.square.fill",
            party: viewModel.draft.buyer,
            update: viewModel.updateBuyer
        )
    }

    func partySection(
        title: String,
        iconName: String,
        party: DocumentParty,
        update: @escaping (DocumentParty) -> Void
    ) -> some View {
        editorSection(title: title, iconName: iconName) {
            VStack(spacing: AppSpacing.md) {
                editorTextField(
                    title: "Название",
                    placeholder: title == "Продавец" ? "Название продавца или исполнителя" : "Название покупателя или клиента",
                    text: partyBinding(party, update: update, keyPath: \.displayName)
                )

                editorTextField(
                    title: "ИНН",
                    placeholder: "7701234567",
                    text: partyBinding(party, update: update, keyPath: \.taxID)
                )

                editorTextField(
                    title: "Рег. номер",
                    placeholder: "КПП / ОГРН",
                    text: partyBinding(party, update: update, keyPath: \.registrationNumber)
                )

                editorTextField(
                    title: "Адрес",
                    placeholder: "Юридический адрес",
                    text: partyBinding(party, update: update, keyPath: \.address),
                    axis: .vertical
                )

                editorTextField(
                    title: "Банк",
                    placeholder: "Название банка",
                    text: partyBinding(party, update: update, keyPath: \.bankName)
                )

                editorTextField(
                    title: "Счёт",
                    placeholder: "Расчётный счёт",
                    text: partyBinding(party, update: update, keyPath: \.bankAccount)
                )

                editorTextField(
                    title: "БИК",
                    placeholder: "044525974",
                    text: partyBinding(party, update: update, keyPath: \.bankCode)
                )

                editorTextField(
                    title: "Контакт",
                    placeholder: "Контактное лицо",
                    text: partyBinding(party, update: update, keyPath: \.contactName)
                )

                editorTextField(
                    title: "Телефон",
                    placeholder: "+7 900 000-00-00",
                    text: partyBinding(party, update: update, keyPath: \.phone)
                )

                editorTextField(
                    title: "Email",
                    placeholder: "email@example.com",
                    text: partyBinding(party, update: update, keyPath: \.email)
                )
            }
        }
    }
}

// MARK: - Items

private extension DocumentEditorScreen {

    var itemsSection: some View {
        editorSection(title: "Позиции", iconName: "list.bullet.rectangle.fill") {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if viewModel.draft.items.isEmpty {
                    emptyItemsPlaceholder
                } else {
                    ForEach(Array(viewModel.draft.items.enumerated()), id: \.element.id) { index, item in
                        itemEditorCard(item, index: index)
                    }
                }

                addItemButton
            }
        }
    }

    var emptyItemsPlaceholder: some View {
        Text("Добавьте товары, услуги или работы, которые попадут в документ.")
            .font(AppFont.Text.caption)
            .foregroundStyle(AppColor.Text.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(.white.opacity(0.38))
            }
    }

    var addItemButton: some View {
        Button {
            viewModel.addItem()
        } label: {
            Label("Добавить позицию", systemImage: "plus.circle.fill")
                .font(AppFont.Control.button)
                .foregroundStyle(AppColor.Brand.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(AppColor.Brand.primary.opacity(0.10))
                }
        }
        .buttonStyle(.plain)
    }

    func itemEditorCard(_ item: DocumentItem, index: Int) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                Text("Позиция \(index + 1)")
                    .font(AppFont.Text.headline)
                    .foregroundStyle(AppColor.Text.primary)

                Spacer()

                Button(role: .destructive) {
                    viewModel.removeItem(id: item.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.Status.danger)
                        .frame(width: 34, height: 34)
                        .background {
                            Circle()
                                .fill(AppColor.Status.dangerBackground.opacity(0.38))
                        }
                }
                .buttonStyle(.plain)
            }

            editorTextField(
                title: "Название",
                placeholder: "Наименование позиции",
                text: Binding(
                    get: { item.title },
                    set: { viewModel.updateItemTitle(id: item.id, title: $0) }
                )
            )

            HStack(alignment: .top, spacing: AppSpacing.sm) {
                decimalTextField(
                    title: "Кол-во",
                    value: Binding(
                        get: { item.quantity },
                        set: { viewModel.updateItemQuantity(id: item.id, quantity: $0) }
                    )
                )

                editorTextField(
                    title: "Ед.",
                    placeholder: "шт",
                    text: Binding(
                        get: { item.unit },
                        set: { viewModel.updateItemUnit(id: item.id, unit: $0) }
                    )
                )
                .frame(width: 82)

                decimalTextField(
                    title: "Цена",
                    value: Binding(
                        get: { item.price },
                        set: { viewModel.updateItemPrice(id: item.id, price: $0) }
                    )
                )
            }

            HStack {
                Text("Сумма")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)

                Spacer()

                Text(itemAmountText(item))
                    .font(AppFont.Text.headline)
                    .foregroundStyle(AppColor.Text.primary)
            }
        }
        .padding(AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(.white.opacity(0.42))
        }
    }
}

// MARK: - Totals & Notes

private extension DocumentEditorScreen {

    var totalsSection: some View {
        editorSection(title: "Итоги", iconName: "sum") {
            VStack(spacing: AppSpacing.sm) {
                infoRow("Позиций", "\(viewModel.totals.itemCount)")
                infoRow("Сумма", totalAmountText, valueWeight: .bold)
            }
        }
    }

    var notesSection: some View {
        editorSection(title: "Комментарий", iconName: "text.alignleft") {
            editorTextField(
                title: "Заметки",
                placeholder: "Комментарий к документу",
                text: notesBinding,
                axis: .vertical
            )
            .lineLimit(4, reservesSpace: true)
        }
    }
}

// MARK: - Save Actions

private extension DocumentEditorScreen {

    var saveActionSection: some View {
        VStack(spacing: AppSpacing.sm) {
            if let errorMessage = viewModel.errorMessage, errorMessage.isEmpty == false {
                errorBanner(errorMessage)
            }

            HStack(spacing: AppSpacing.sm) {
                Button {
                    viewModel.didTapPreview()
                } label: {
                    Label("Предпросмотр", systemImage: "doc.richtext")
                        .font(AppFont.Control.button)
                        .foregroundStyle(AppColor.Text.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background {
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(.white.opacity(0.72))
                        }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.canSave == false || viewModel.isSaving)

                Button {
                    Task {
                        await viewModel.didTapSave()
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        if viewModel.isSaving {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        }

                        Text(viewModel.isSaving ? "Сохраняем" : "Сохранить")
                    }
                    .font(AppFont.Control.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                            .fill(viewModel.canSave ? AppColor.Brand.primary : .gray.opacity(0.45))
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.canSave == false || viewModel.isSaving)
            }
        }
    }

    func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColor.Status.danger)

            Text(message)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Status.danger)
                .frame(maxWidth: .infinity)
        }
        .padding(AppSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColor.Status.dangerBackground.opacity(0.46))
        }
    }
}

// MARK: - Display Formatting

private extension DocumentEditorScreen {

    var totalAmountText: String {
        CurrencyFormatter.amountText(
            viewModel.totals.total,
            currencyCode: viewModel.draft.currencyCode
        )
    }

    func itemAmountText(_ item: DocumentItem) -> String {
        CurrencyFormatter.amountText(
            item.amount,
            currencyCode: viewModel.draft.currencyCode
        )
    }

    func iconName(for type: DocumentType) -> String {
        switch type {
        case .invoice:
            return "doc.text.fill"

        case .act:
            return "checkmark.seal.fill"

        case .deliveryNote:
            return "shippingbox.fill"
        }
    }
}

// MARK: - Bindings

private extension DocumentEditorScreen {

    var documentNumberBinding: Binding<String> {
        Binding(
            get: { viewModel.draft.number },
            set: { viewModel.updateNumber($0) }
        )
    }

    var documentDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.draft.date },
            set: { viewModel.updateDate($0) }
        )
    }

    var currencyCodeBinding: Binding<String> {
        Binding(
            get: { viewModel.draft.currencyCode },
            set: { viewModel.updateCurrencyCode($0) }
        )
    }

    var notesBinding: Binding<String> {
        Binding(
            get: { viewModel.draft.notes },
            set: { viewModel.updateNotes($0) }
        )
    }

    func partyBinding(
        _ party: DocumentParty,
        update: @escaping (DocumentParty) -> Void,
        keyPath: WritableKeyPath<DocumentParty, String>
    ) -> Binding<String> {
        Binding(
            get: {
                party[keyPath: keyPath]
            },
            set: { newValue in
                var updatedParty = party
                updatedParty[keyPath: keyPath] = newValue
                update(updatedParty)
            }
        )
    }
}

// MARK: - Components

private extension DocumentEditorScreen {

    func editorSection<Content: View>(
        title: String,
        iconName: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.Text.secondary)

                    Text(title)
                        .font(AppFont.Text.headline)
                        .foregroundStyle(AppColor.Text.primary)
                }

                content()
            }
        }
    }

    func editorTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            TextField(placeholder, text: text, axis: axis)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(axis == .vertical ? 3 : 1, reservesSpace: axis == .vertical)
                .padding(.horizontal, AppSpacing.md)
                .frame(minHeight: 46)
                .background {
                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                        .fill(.white.opacity(0.58))
                }
        }
    }

    func decimalTextField(
        title: String,
        value: Binding<Decimal>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            TextField(
                "0",
                value: value,
                formatter: Self.numberFormatter
            )
            .keyboardType(.decimalPad)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppColor.Text.primary)
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 46)
            .background {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .fill(.white.opacity(0.58))
            }
        }
    }

    func infoRow(
        _ title: String,
        _ value: String,
        valueWeight: Font.Weight = .semibold
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.md) {
            Text(title)
                .font(AppFont.Text.caption)
                .foregroundStyle(AppColor.Text.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: valueWeight))
                .foregroundStyle(AppColor.Text.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    // MARK: - Formatters

    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}

// MARK: - Preview

#Preview("New Invoice") {
    NavigationStack {
        DocumentEditorScreen(
            viewModel: DocumentEditorViewModel(
                mode: .create(.invoice),
                router: PreviewDocumentsRouter(),
                documentsRepository: InMemoryDocumentsRepository(documents: []),
                documentFactory: DocumentFactory(),
                documentValidator: DocumentValidator()
            )
        )
    }
}

#Preview("New Act") {
    NavigationStack {
        DocumentEditorScreen(
            viewModel: DocumentEditorViewModel(
                mode: .create(.act),
                router: PreviewDocumentsRouter(),
                documentsRepository: InMemoryDocumentsRepository(documents: []),
                documentFactory: DocumentFactory(),
                documentValidator: DocumentValidator()
            )
        )
    }
}

#Preview("Edit Invoice") {
    NavigationStack {
        DocumentEditorScreen(
            viewModel: DocumentEditorViewModel(
                mode: .edit(PreviewDocumentFixtures.invoice),
                router: PreviewDocumentsRouter(),
                documentsRepository: InMemoryDocumentsRepository(documents: [PreviewDocumentFixtures.invoice]),
                documentFactory: DocumentFactory(),
                documentValidator: DocumentValidator()
            )
        )
    }
}

#Preview("Edit Delivery Note") {
    NavigationStack {
        DocumentEditorScreen(
            viewModel: DocumentEditorViewModel(
                mode: .edit(PreviewDocumentFixtures.deliveryNote),
                router: PreviewDocumentsRouter(),
                documentsRepository: InMemoryDocumentsRepository(documents: [PreviewDocumentFixtures.deliveryNote]),
                documentFactory: DocumentFactory(),
                documentValidator: DocumentValidator()
            )
        )
    }
}

// MARK: - Preview Router

private final class PreviewDocumentsRouter: DocumentsCoordinatorProtocol {
    func start() { }
    func showDetail(document: BusinessDocument) { }
    func showCreateDocument(type: DocumentType) { }
    func showEditDocument(document: BusinessDocument) { }
    func showPreview(document: BusinessDocument) { }
    func finishDocumentFlowAfterShare() { }
    func dismiss() { }
    func pop() { }
}

// MARK: - Preview Fixtures

private enum PreviewDocumentFixtures {

    static let invoice = BusinessDocument(
        type: .invoice,
        number: "INV-2026-001",
        date: Date(),
        seller: seller,
        buyer: alfaBuyer,
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
    )

    static let deliveryNote = BusinessDocument(
        type: .deliveryNote,
        number: "DN-2026-008",
        date: Date(),
        seller: seller,
        buyer: retailBuyer,
        items: [
            DocumentItem(
                title: "Термопринтер",
                quantity: 2,
                unit: "шт",
                price: 12_000
            ),
            DocumentItem(
                title: "Рулоны чековой ленты",
                quantity: 10,
                unit: "шт",
                price: 180
            )
        ],
        notes: "Передача товара по адресу склада покупателя.",
        currencyCode: "RUB",
        status: .draft
    )

    static let seller = DocumentParty(
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
    )

    static let alfaBuyer = DocumentParty(
        displayName: "ООО Альфа",
        taxID: "7701234567",
        registrationNumber: "",
        address: "г. Москва, ул. Тверская, 8",
        bankName: "",
        bankAccount: "",
        bankCode: "",
        contactName: "",
        phone: "+7 999 123-45-67",
        email: "pay@alfa.ru"
    )

    static let retailBuyer = DocumentParty(
        displayName: "ООО Ритейл Плюс",
        taxID: "5904123456",
        registrationNumber: "",
        address: "г. Челябинск, пр. Победы, 21",
        bankName: "",
        bankAccount: "",
        bankCode: "",
        contactName: "",
        phone: "+7 951 300-40-50",
        email: "office@retailplus.ru"
    )
}
