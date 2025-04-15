import Combine
import Foundation

@MainActor
final class TabBarVisibilityStore: ObservableObject {
    @Published var isHidden = false

    func setHidden(_ isHidden: Bool) {
        self.isHidden = isHidden
    }
}
