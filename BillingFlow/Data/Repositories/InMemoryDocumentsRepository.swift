import Foundation

actor InMemoryDocumentsRepository: DocumentsRepositoryProtocol {

    // MARK: - Properties

    private var documents: [BusinessDocument]

    // MARK: - Initialization

    init(documents: [BusinessDocument]? = nil) {
        self.documents = documents ?? Self.mockDocuments()
    }

    init(documents: [BusinessDocument]) {
        self.documents = documents
    }

    // MARK: - Fetching Documents

    func fetchDocuments() async throws -> [BusinessDocument] {
        documents.sorted(by: { $0.date > $1.date })
    }

    func fetchDocument(id: UUID) async throws -> BusinessDocument? {
        documents.first(where: { $0.id == id })
    }

    // MARK: - Mutating Documents

    func save(document: BusinessDocument) async throws {
        if let existingIndex = documents.firstIndex(where: { $0.id == document.id }) {
            documents[existingIndex] = document
            return
        }

        documents.append(document)
    }

    func deleteDocument(id: UUID) async throws {
        documents.removeAll(where: { $0.id == id })
    }
}

// MARK: - Mock Data

private extension InMemoryDocumentsRepository {

    private static func mockDocuments() -> [BusinessDocument] {
        [
            makeInvoiceDocument(),
            makeActDocument(),
            makeDeliveryNoteDocument()
        ]
    }

    private static func makeInvoiceDocument() -> BusinessDocument {
        BusinessDocument(
            type: .invoice,
            number: "001",
            date: Date(timeIntervalSinceNow: -86_400),
            seller: sellerParty(),
            buyer: buyerParty(),
            items: [
                DocumentItem(
                    title: "Разработка интерфейса",
                    quantity: 1,
                    unit: "услуга",
                    price: 45_000
                ),
                DocumentItem(
                    title: "Интеграция платежей",
                    quantity: 1,
                    unit: "услуга",
                    price: 25_000
                )
            ],
            notes: "Оплата в течение 5 рабочих дней.",
            currencyCode: "RUB",
            status: .ready
        )
    }

    private static func makeActDocument() -> BusinessDocument {
        BusinessDocument(
            type: .act,
            number: "АКТ-014",
            date: Date(timeIntervalSinceNow: -259_200),
            seller: sellerParty(),
            buyer: buyerParty(),
            items: [
                DocumentItem(
                    title: "Поддержка приложения",
                    quantity: 2,
                    unit: "час",
                    price: 3_500
                ),
                DocumentItem(
                    title: "Исправление багов",
                    quantity: 4,
                    unit: "час",
                    price: 2_500
                )
            ],
            notes: "Работы выполнены в полном объеме.",
            currencyCode: "RUB",
            status: .shared
        )
    }

    private static func makeDeliveryNoteDocument() -> BusinessDocument {
        BusinessDocument(
            type: .deliveryNote,
            number: "ОСТ-008",
            date: Date(timeIntervalSinceNow: -518_400),
            seller: supplierParty(),
            buyer: recipientParty(),
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
    }

    private static func sellerParty() -> DocumentParty {
        DocumentParty(
            displayName: "ИП Иванов И.И.",
            taxID: "770123456789",
            registrationNumber: "123456789012345",
            address: "г. Москва, ул. Мира, 10",
            bankName: "АО Т-Банк",
            bankAccount: "40802810900000000001",
            bankCode: "044525974",
            contactName: "Иван Иванов",
            phone: "+7 912 000-00-01",
            email: "ivanov@example.com"
        )
    }

    private static func buyerParty() -> DocumentParty {
        DocumentParty(
            displayName: "ООО Альфа",
            taxID: "6678123456",
            registrationNumber: "1186658001234",
            address: "г. Москва, ул. Лесная, 15",
            bankName: "ПАО Сбербанк",
            bankAccount: "40702810400000000025",
            bankCode: "044525225",
            contactName: "Мария Смирнова",
            phone: "+7 999 100-20-30",
            email: "accounting@alfa.ru"
        )
    }

    private static func supplierParty() -> DocumentParty {
        DocumentParty(
            displayName: "ООО ТехСнаб",
            taxID: "6659123456",
            registrationNumber: "1166659005678",
            address: "г. Пермь, ул. Заводская, 4",
            bankName: "АО Альфа-Банк",
            bankAccount: "40702810400000000456",
            bankCode: "044525593",
            contactName: "Павел Кузнецов",
            phone: "+7 922 200-10-10",
            email: "sales@tehsnab.ru"
        )
    }

    private static func recipientParty() -> DocumentParty {
        DocumentParty(
            displayName: "ООО Ритейл Плюс",
            taxID: "5904123456",
            registrationNumber: "1145904009876",
            address: "г. Челябинск, пр. Победы, 21",
            bankName: "ПАО ВТБ",
            bankAccount: "40702810700000007890",
            bankCode: "046577964",
            contactName: "Елена Орлова",
            phone: "+7 951 300-40-50",
            email: "office@retailplus.ru"
        )
    }
}
