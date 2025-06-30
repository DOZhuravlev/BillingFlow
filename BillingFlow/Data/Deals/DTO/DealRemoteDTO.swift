import Foundation

nonisolated struct DealRemoteDTO: Decodable, Sendable {
    let id: String
    let title: String
    let type: String
    let counterparty: DocumentParty
    let amount: String
    let currencyCode: String
    let statusOverride: String?
    let dueDate: String?
    let reminderDate: String?
    let note: String
    let phone: String
    let revision: Int64
    let createdAt: String
    let updatedAt: String
}

nonisolated struct DealUpsertRemoteDTO: Encodable, Sendable {
    let title: String
    let type: String
    let counterparty: DocumentParty
    let amount: String
    let currencyCode: String
    let statusOverride: String?
    let dueDate: String?
    let reminderDate: String?
    let note: String
    let phone: String
    let revision: Int64
}

nonisolated struct DealsRemoteResponse: Decodable, Sendable {
    let items: [DealRemoteDTO]
}

nonisolated struct DeleteDealRemoteResponse: Decodable, Sendable {
    let ok: Bool
}
