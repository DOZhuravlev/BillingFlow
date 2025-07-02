import Foundation

struct NotificationRoute: Sendable, Equatable {
    enum RouteType: String, Sendable {
        case paymentReminder
        case document
        case deal
        case news
    }

    let type: RouteType
    let documentID: UUID?
    let dealID: UUID?
    let newsID: UUID?
}

extension NotificationRoute {
    init?(userInfo: [AnyHashable: Any]) {
        guard let typeValue = userInfo["type"] as? String,
              let type = RouteType(rawValue: typeValue) else {
            return nil
        }

        self.type = type
        self.documentID = Self.uuid(for: "documentID", in: userInfo)
        self.dealID = Self.uuid(for: "dealID", in: userInfo)
        self.newsID = Self.uuid(for: "newsID", in: userInfo)
    }

    private static func uuid(for key: String, in userInfo: [AnyHashable: Any]) -> UUID? {
        guard let value = userInfo[key] as? String else { return nil }
        return UUID(uuidString: value)
    }
}
