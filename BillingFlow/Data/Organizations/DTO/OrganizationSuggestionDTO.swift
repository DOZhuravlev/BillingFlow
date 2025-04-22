import Foundation

struct OrganizationSuggestionDTO: Decodable {
    let name: String
    let shortName: String?
    let inn: String
    let kpp: String?
    let ogrn: String?
    let address: String?
    let managerName: String?
    let managerPost: String?
}

struct OrganizationSuggestionsResponseDTO: Decodable {
    let items: [OrganizationSuggestionDTO]
}

struct OrganizationSuggestRequestDTO: Encodable {
    let query: String
    let limit: Int
}
