import Foundation

enum DocumentStatus: String, Codable, Hashable, Sendable {
    case draft
    case ready
    case shared

    var displayName: String {
        switch self {
        case .draft:
            return "Черновик"
        case .ready:
            return "Готов"
        case .shared:
            return "Отправлен"
        }
    }
}
