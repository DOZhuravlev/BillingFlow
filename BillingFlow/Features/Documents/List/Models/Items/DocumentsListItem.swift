import SwiftUI

struct DocumentsListItem: Identifiable, Equatable {
    let id: UUID
    let iconName: String
    let iconStyle: IconStyle
    let title: String
    let counterpartyName: String
    let dateText: String
    let amountText: String
    let statusText: String
    let statusStyle: StatusStyle
    let footerText: String
    let primaryActionTitle: String?
    let secondaryActionTitle: String?
}

extension DocumentsListItem {

    enum IconStyle: Equatable {
        case orange
        case green
        case purple

        var tintColor: Color {
            switch self {
            case .orange:
                return .orange

            case .green:
                return .green

            case .purple:
                return .purple
            }
        }

        var backgroundColor: Color {
            tintColor.opacity(0.14)
        }
    }

    enum StatusStyle: Equatable {
        case neutral
        case positive
        case warning
        case negative

        var tintColor: Color {
            switch self {
            case .neutral:
                return .gray

            case .positive:
                return .green

            case .warning:
                return .orange

            case .negative:
                return .red
            }
        }

        var backgroundColor: Color {
            tintColor.opacity(0.14)
        }
    }
}
