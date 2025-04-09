import SwiftUI

struct DocumentsHeaderView: View {
    let counterpartyTitle: String
    let hasActiveFilters: Bool
    let onCounterpartyTap: () -> Void
    let onSearchTap: () -> Void
    let onFilterTap: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            counterpartyButton

            Spacer(minLength: 8)

            iconButton(systemName: "magnifyingglass", action: onSearchTap)
            filterButton
        }
    }

    private var counterpartyButton: some View {
        Button(action: onCounterpartyTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Документы")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: 7) {
                    Text(counterpartyTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var filterButton: some View {
        Button(action: onFilterTap) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background {
                        Circle()
                            .fill(.white.opacity(0.16))
                    }

                if hasActiveFilters {
                    Circle()
                        .fill(.white)
                        .frame(width: 9, height: 9)
                        .offset(x: -5, y: 5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func iconButton(
        systemName: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background {
                    Circle()
                        .fill(.white.opacity(0.16))
                }
        }
        .buttonStyle(.plain)
    }
}
