import SwiftUI

final class HostingController<Content: View>: UIHostingController<Content> {

    init(
        rootView: Content,
        navigationTitle: String? = nil,
        leftBarButtonItems: [UIBarButtonItem]? = nil,
        rightBarButtonItems: [UIBarButtonItem]? = nil,
        hidesBackButton: Bool = false,
        titleDisplayMode: UINavigationItem.LargeTitleDisplayMode = .automatic
    ) {
        super.init(rootView: rootView)

        navigationItem.title = navigationTitle
        navigationItem.leftBarButtonItems = leftBarButtonItems
        navigationItem.rightBarButtonItems = rightBarButtonItems
        navigationItem.hidesBackButton = hidesBackButton
        navigationItem.largeTitleDisplayMode = titleDisplayMode
    }

    convenience init(
        rootView: Content,
        navigationTitle: String? = nil,
        leftBarButtonItems: [UIBarButtonItem]? = nil,
        rightBarButtonTitle: String,
        rightBarButtonAction: @escaping () -> Void,
        hidesBackButton: Bool = false,
        titleDisplayMode: UINavigationItem.LargeTitleDisplayMode = .automatic
    ) {
        let action = UIAction { _ in rightBarButtonAction() }
        let rightButton = UIBarButtonItem(title: rightBarButtonTitle, primaryAction: action, menu: nil)
        self.init(
            rootView: rootView,
            navigationTitle: navigationTitle,
            leftBarButtonItems: leftBarButtonItems,
            rightBarButtonItems: [rightButton],
            hidesBackButton: hidesBackButton,
            titleDisplayMode: titleDisplayMode
        )
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
