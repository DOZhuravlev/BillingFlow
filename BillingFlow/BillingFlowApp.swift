import SwiftUI

@main
struct BillingFlowApp: App {
    var body: some Scene {
        WindowGroup {
            //DocumentsScreen(repository: InMemoryDocumentsRepository())
            DocumentPreviewScreen(document: mockDocument)
        }
    }


    let mockDocument = BusinessDocument(
            type: .invoice,
            number: "INV-2026-001",
            date: Date(),
            seller: DocumentParty(
                displayName: "ООО BillingFlow Studio",
                taxID: "6678123456",
                registrationNumber: "667801001",
                address: "г. Екатеринбург, ул. Горького, 12",
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
                address: "г. Москва, ул. Тверская, 8",
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
    )
    
}
