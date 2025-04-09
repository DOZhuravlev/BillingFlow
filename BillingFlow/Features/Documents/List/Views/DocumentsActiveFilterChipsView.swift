import SwiftUI

struct DocumentsActiveFilterChipsView: View {
    let chips: [DocumentsFilterChipItem]
    let onRemove: (DocumentsFilterChipItem) -> Void
    let onReset: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(chips) { chip in
                    chipView(chip)
                }
                resetButton
            }
            .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
    }

    private func chipView(_ chip: DocumentsFilterChipItem) -> some View {
        Button {
            onRemove(chip)
        } label: {
            HStack(spacing: 6) {
                Text(chip.title)
                    .lineLimit(1)

                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.black.opacity(0.72))
            .padding(.horizontal, 13)
            .frame(height: 36)
            .background {
                Capsule()
                    .fill(.white.opacity(0.72))
            }
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.45), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var resetButton: some View {
        Button(action: onReset) {
            Text("Сбросить")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 13)
                .frame(height: 36)
                .background {
                    Capsule()
                        .fill(.white.opacity(0.14))
                }
        }
        .buttonStyle(.plain)
    }
}
