import Foundation

nonisolated struct DocumentRemoteDTO: Decodable, Sendable {
    let id: String
    let type: String
    let number: String
    let date: String
    let seller: DocumentParty
    let buyer: DocumentParty
    let items: [DocumentItem]
    let notes: String
    let currencyCode: String
    let status: String
    let paidAt: String?
    let paymentReminderDate: String?
    let dealID: String?
    let draftStepRawValue: Int?
    let revision: Int64
    let createdAt: String
    let updatedAt: String
}

nonisolated struct DocumentUpsertRemoteDTO: Encodable, Sendable {
    let type: String
    let number: String
    let date: String
    let seller: DocumentParty
    let buyer: DocumentParty
    let items: [DocumentItem]
    let notes: String
    let currencyCode: String
    let status: String
    let paidAt: String?
    let paymentReminderDate: String?
    let dealID: String?
    let draftStepRawValue: Int?
    let revision: Int64
}

nonisolated struct DocumentsRemoteResponse: Decodable, Sendable {
    let items: [DocumentRemoteDTO]
}

nonisolated struct DeleteDocumentRemoteResponse: Decodable, Sendable {
    let ok: Bool
}
