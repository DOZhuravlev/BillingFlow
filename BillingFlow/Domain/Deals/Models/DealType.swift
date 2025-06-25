import Foundation

enum DealType: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case services
    case goods
    case goodsAndServices
    case rent
    case contracting

    var id: String { rawValue }

    var title: String {
        switch self {
        case .services: return "Услуги"
        case .goods: return "Товар"
        case .goodsAndServices: return "Товар + услуга"
        case .rent: return "Аренда"
        case .contracting: return "Подряд"
        }
    }

    var iconName: String {
        switch self {
        case .services: return "person.2.fill"
        case .goods: return "shippingbox.fill"
        case .goodsAndServices: return "square.grid.2x2.fill"
        case .rent: return "key.fill"
        case .contracting: return "hammer.fill"
        }
    }
}
