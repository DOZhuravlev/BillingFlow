import Foundation

enum AppSheet: Identifiable, Equatable {
    case createDocument
    case paywall(PaywallSource)
    case organizationSwitcher

    var id: String {
        switch self {
        case .createDocument:
            "createDocument"

        case .paywall(let source):
            "paywall-\(source.rawValue)"

        case .organizationSwitcher:
            "organizationSwitcher"
        }
    }
}
