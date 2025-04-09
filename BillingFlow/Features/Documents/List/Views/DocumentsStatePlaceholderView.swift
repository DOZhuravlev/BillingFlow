import SwiftUI

struct DocumentsStatePlaceholderView: View {
    let title: String
    let message: String
    let systemImage: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            icon
            textBlock
            actionButton
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(background)
    }

    private var icon: some View {
        Image(systemName: systemImage)
            .font(.system(size: 36, weight: .medium))
            .foregroundStyle(.secondary)
    }

    private var textBlock: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var actionButton: some View {
        Button(buttonTitle, action: action)
            .buttonStyle(.borderedProminent)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.white.opacity(0.75))
    }
}
