import SwiftUI

struct DocumentPreviewWebView: UIViewRepresentable {

    let html: String
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    func makeUIView(context: Context) -> PreviewContainerView {
        let containerView = PreviewContainerView()
        containerView.onLoadingStateChange = context.coordinator.updateLoadingState
        containerView.loadHTMLIfNeeded(html)
        return containerView
    }

    func updateUIView(_ view: PreviewContainerView, context: Context) {
        context.coordinator.isLoading = $isLoading
        view.onLoadingStateChange = context.coordinator.updateLoadingState
        view.loadHTMLIfNeeded(html)
    }

    final class Coordinator {
        var isLoading: Binding<Bool>

        init(isLoading: Binding<Bool>) {
            self.isLoading = isLoading
        }

        func updateLoadingState(_ isLoading: Bool) {
            self.isLoading.wrappedValue = isLoading
        }
    }
}
