import SwiftUI

struct DocumentPreviewWebView: UIViewRepresentable {

    let html: String

    func makeUIView(context: Context) -> PreviewContainerView {
        let containerView = PreviewContainerView()
        containerView.loadHTMLIfNeeded(html)
        return containerView
    }

    func updateUIView(_ view: PreviewContainerView, context: Context) {
        view.loadHTMLIfNeeded(html)
    }
}
