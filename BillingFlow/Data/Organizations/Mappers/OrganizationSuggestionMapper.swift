import Foundation

struct OrganizationSuggestionMapper {
    func map(_ dto: OrganizationSuggestionDTO) -> OrganizationSuggestion {
        OrganizationSuggestion(
            name: dto.name,
            shortName: dto.shortName ?? "",
            inn: dto.inn,
            kpp: dto.kpp ?? "",
            ogrn: dto.ogrn ?? "",
            address: dto.address ?? "",
            managerName: dto.managerName ?? "",
            managerPost: dto.managerPost ?? ""
        )
    }
}
