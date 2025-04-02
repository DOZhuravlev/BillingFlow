import SwiftUI

struct MaterialCard<Content: View>: View {

    // MARK: - Properties

    private let cornerRadius: CGFloat
    private let padding: CGFloat
    private let content: Content

    // MARK: - Initialization

    init(
        cornerRadius: CGFloat = AppRadius.lg,
        padding: CGFloat = AppSpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(.white.opacity(0.35), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
            }
    }
}

#Preview {
    MaterialCard(cornerRadius: 10) {
        Text("Stay")
    }
}
