import SwiftUI
import UIKit

struct ScrollOffsetObserver: UIViewRepresentable {

    // MARK: - Dependencies

    let onChange: (CGPoint) -> Void

    // MARK: - Public API

    func makeUIView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.onChange = onChange
        return view
    }

    func updateUIView(_ uiView: ObserverView, context: Context) {
        uiView.onChange = onChange
        uiView.attachIfNeeded()
    }

    // MARK: - Private API / Helpers

    final class ObserverView: UIView {

        // MARK: - Dependencies

        var onChange: ((CGPoint) -> Void)?

        // MARK: - State

        private weak var observedScrollView: UIScrollView?
        private var observation: NSKeyValueObservation?

        // MARK: - Lifecycle

        override func didMoveToWindow() {
            super.didMoveToWindow()

            DispatchQueue.main.async { [weak self] in
                self?.attachIfNeeded()
            }
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()

            DispatchQueue.main.async { [weak self] in
                self?.attachIfNeeded()
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            DispatchQueue.main.async { [weak self] in
                self?.attachIfNeeded()
            }
        }

        deinit {
            observation?.invalidate()
        }

        // MARK: - Public API

        func attachIfNeeded() {
            if observedScrollView != nil {
                return
            }

            guard let scrollView = findScrollView() else {
                print("SCROLL OBSERVER: UIScrollView not found")
                return
            }

            print("SCROLL OBSERVER: attached", scrollView)

            observedScrollView = scrollView
            onChange?(scrollView.contentOffset)

            observation = scrollView.observe(
                \.contentOffset,
                 options: [.new]
            ) { [weak self] scrollView, _ in
                DispatchQueue.main.async {
                    self?.onChange?(scrollView.contentOffset)
                }
            }
        }

        // MARK: - Private API / Helpers

        private func findScrollView() -> UIScrollView? {
            if let scrollView = findSuperview(of: UIScrollView.self) {
                return scrollView
            }

            guard let window else {
                return nil
            }

            return findSubview(of: UIScrollView.self, in: window)
        }

        private func findSuperview<T: UIView>(of type: T.Type) -> T? {
            var currentView = superview

            while let view = currentView {
                if let typedView = view as? T {
                    return typedView
                }

                currentView = view.superview
            }

            return nil
        }

        private func findSubview<T: UIView>(
            of type: T.Type,
            in rootView: UIView
        ) -> T? {
            if let typedView = rootView as? T {
                return typedView
            }

            for subview in rootView.subviews {
                if let foundView = findSubview(of: type, in: subview) {
                    return foundView
                }
            }

            return nil
        }
    }
}
