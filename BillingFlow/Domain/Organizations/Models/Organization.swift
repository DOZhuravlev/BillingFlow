import Foundation

struct Organization: Identifiable, Codable, Hashable, Sendable {
    enum Role: String, Codable, Sendable {
        case seller
        case buyer
        case mixed

        var title: String {
            switch self {
            case .seller:
                return "Продавец"
            case .buyer:
                return "Покупатель"
            case .mixed:
                return "Контрагент"
            }
        }
    }

    var id: UUID
    var party: DocumentParty
    var role: Role
    var createdAt: Date
    var updatedAt: Date

    var matchingKey: String {
        let taxID = party.taxID
            .filter(\.isNumber)

        if taxID.isEmpty == false {
            return "tax:\(taxID)"
        }

        return "name:\(party.displayName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    init(
        id: UUID = UUID(),
        party: DocumentParty,
        role: Role,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.party = party
        self.role = role
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
