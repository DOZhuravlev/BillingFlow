import SwiftUI

struct DocumentsMonthSectionView: View {
    let section: DocumentsListSection
    let onDocumentTap: (BusinessDocument) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            LazyVStack(spacing: 12) {
                ForEach(section.items) { row in
                    Button {
                        onDocumentTap(row.document)
                    } label: {
                        documentCard(for: row.item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var sectionHeader: some View {
        HStack {
            Text(section.title)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))

            Spacer()

            Text(section.countText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private func documentCard(for item: DocumentsListItem) -> some View {
        BillGroupCard(
            iconName: item.iconName,
            title: item.title,
            date: "\(item.counterpartyName) • \(item.dateText)",
            amount: item.amountText,
            statusTitle: "Статус",
            statusAmount: item.statusText,
            statusStyle: statusPillStyle(for: item.statusStyle)
        )
    }

    private func statusPillStyle(for style: DocumentsListItem.StatusStyle) -> StatusPill.Style {
        switch style {
        case .positive:
            return .positive

        case .negative:
            return .negative

        case .neutral, .warning:
            return .neutral
        }
    }
}
