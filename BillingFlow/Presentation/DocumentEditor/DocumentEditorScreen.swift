import SwiftUI

struct DocumentEditorScreen: View {

    // MARK: - ViewModel

    @ObservedObject var viewModel: DocumentEditorViewModel

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                headerSection
                documentMetaSection
                sellerSection
                buyerSection
                itemsSection
                totalsSection
                notesSection
                saveActionSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .scrollIndicators(.hidden)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(screenTitle)
                .font(.title.weight(.bold))
                .foregroundStyle(.primary)

            Text("Заполните основные данные и добавьте позиции. Итоги пересчитаются автоматически.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Document Meta Section

    private var documentMetaSection: some View {
        sectionCard(title: "Документ") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(viewModel.draft.type.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(typeTint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(typeTint.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()
                }

                TextField("Номер документа", text: documentNumberBinding)
                    .textFieldStyle(.roundedBorder)

                DatePicker(
                    "Дата",
                    selection: documentDateBinding,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }
        }
    }

    // MARK: - Seller Section

    private var sellerSection: some View {
        sectionCard(title: "Продавец") {
            TextField("Название продавца или исполнителя", text: sellerNameBinding)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Buyer Section

    private var buyerSection: some View {
        sectionCard(title: "Покупатель") {
            TextField("Название покупателя или клиента", text: buyerNameBinding)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Items Section

    private var itemsSection: some View {
        sectionCard(title: "Позиции") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(viewModel.draft.items) { item in
                    itemEditorCard(item)
                }

                Button {
                    viewModel.addItem()
                } label: {
                    Label("Добавить позицию", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
    }

    // MARK: - Totals Section

    private var totalsSection: some View {
        sectionCard(title: "Итоги") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Позиций")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(viewModel.totals.itemCount)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Сумма")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(totalAmountText)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        sectionCard(title: "Заметки") {
            TextField(
                "Комментарий к документу",
                text: notesBinding,
                axis: .vertical
            )
            .lineLimit(4, reservesSpace: true)
            .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Save Action Section

    private var saveActionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let errorMessage = viewModel.errorMessage, errorMessage.isEmpty == false {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    await viewModel.didTapSave()
                }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }

                    Text(viewModel.isSaving ? "Сохраняем..." : "Сохранить документ")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(viewModel.canSave == false || viewModel.isSaving)
        }
        .padding(.top, 4)
    }

    // MARK: - Screen Configuration

    private var screenTitle: String {
        switch viewModel.draft.type {
        case .invoice:
            return viewModel.isEditing ? "Редактирование счета" : "Новый счет"
        case .act:
            return viewModel.isEditing ? "Редактирование акта" : "Новый акт"
        case .deliveryNote:
            return viewModel.isEditing ? "Редактирование накладной" : "Новая накладная"
        }
    }

    private var typeTint: Color {
        switch viewModel.draft.type {
        case .invoice:
            return .blue
        case .act:
            return .green
        case .deliveryNote:
            return .orange
        }
    }

    // MARK: - Display Formatting

    private var totalAmountText: String {
        let number = NSDecimalNumber(decimal: viewModel.totals.total)
        let formattedAmount = Self.amountFormatter.string(from: number) ?? number.stringValue
        return "\(formattedAmount) \(viewModel.draft.currencyCode)"
    }

    private func itemAmountText(_ item: DocumentItem) -> String {
        let number = NSDecimalNumber(decimal: item.amount)
        let formattedAmount = Self.amountFormatter.string(from: number) ?? number.stringValue
        return "\(formattedAmount) \(viewModel.draft.currencyCode)"
    }

    // MARK: - Field Bindings

    private var documentNumberBinding: Binding<String> {
        Binding(
            get: { viewModel.draft.number },
            set: { viewModel.updateNumber($0) }
        )
    }

    private var documentDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.draft.date },
            set: { viewModel.updateDate($0) }
        )
    }

    private var sellerNameBinding: Binding<String> {
        Binding(
            get: { viewModel.draft.seller.displayName },
            set: { newValue in
                var seller = viewModel.draft.seller
                seller.displayName = newValue
                viewModel.updateSeller(seller)
            }
        )
    }

    private var buyerNameBinding: Binding<String> {
        Binding(
            get: { viewModel.draft.buyer.displayName },
            set: { newValue in
                var buyer = viewModel.draft.buyer
                buyer.displayName = newValue
                viewModel.updateBuyer(buyer)
            }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { viewModel.draft.notes },
            set: { viewModel.updateNotes($0) }
        )
    }

    // MARK: - Reusable Section UI

    private func sectionCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 8)
    }

    // MARK: - Item Editor UI

    private func itemEditorCard(_ item: DocumentItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                TextField(
                    "Наименование",
                    text: Binding(
                        get: { item.title },
                        set: { viewModel.updateItemTitle(id: item.id, title: $0) }
                    )
                )
                .textFieldStyle(.roundedBorder)

                Button(role: .destructive) {
                    viewModel.removeItem(id: item.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderless)
            }

            HStack(spacing: 10) {
                TextField(
                    "Кол-во",
                    value: Binding(
                        get: { item.quantity },
                        set: { viewModel.updateItemQuantity(id: item.id, quantity: $0) }
                    ),
                    formatter: Self.numberFormatter
                )
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)

                TextField(
                    "Ед.",
                    text: Binding(
                        get: { item.unit },
                        set: { viewModel.updateItemUnit(id: item.id, unit: $0) }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 84)

                TextField(
                    "Цена",
                    value: Binding(
                        get: { item.price },
                        set: { viewModel.updateItemPrice(id: item.id, price: $0) }
                    ),
                    formatter: Self.numberFormatter
                )
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
            }

            HStack {
                Spacer()

                Text(itemAmountText(item))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.025))
        )
    }

    // MARK: - Formatters

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = " "
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

private final class PreviewDocumentsRouter: DocumentsRouterProtocol {
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
