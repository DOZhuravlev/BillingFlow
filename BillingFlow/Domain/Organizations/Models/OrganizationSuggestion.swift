import Foundation

struct OrganizationSuggestion: Identifiable, Hashable, Sendable {
    var id: String {
        [inn, kpp, ogrn, name]
            .filter { $0.isEmpty == false }
            .joined(separator: ":")
    }

    let name: String
    let shortName: String
    let inn: String
    let kpp: String
    let ogrn: String
    let address: String
    let managerName: String
    let managerPost: String

    var party: DocumentParty {
        DocumentParty(
            displayName: name,
            taxID: inn,
            registrationNumber: registrationText,
            address: address,
            contactName: managerName
        )
    }

    private var registrationText: String {
        [kpp.isEmpty ? nil : "КПП \(kpp)", ogrn.isEmpty ? nil : "ОГРН \(ogrn)"]
            .compactMap { $0 }
            .joined(separator: " / ")
    }
}
