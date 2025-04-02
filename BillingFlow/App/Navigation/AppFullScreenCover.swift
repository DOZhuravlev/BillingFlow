import Foundation

enum AppFullScreenCover: Identifiable, Equatable {
    case onboarding

    var id: String {
        switch self {
        case .onboarding:
            "onboarding"
        }
    }
}
