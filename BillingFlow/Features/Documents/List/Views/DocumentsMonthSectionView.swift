import SwiftUI

struct DocumentsMonthSectionView: View {
    let section: DocumentsListSection
    let onDocumentTap: (BusinessDocument) -> Void
    let onDocumentDelete: (BusinessDocument) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            LazyVStack(spacing: 12) {
                ForEach(section.items) { row in
                    DocumentsSwipeRow(
                        onTap: {
                            onDocumentTap(row.document)
                        },
                        onDelete: {
                            onDocumentDelete(row.document)
                        }
                    ) {
                        documentCard(for: row.item)
                    }
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
            title: item.counterpartyName,
            date: "\(item.title) от \(item.dateText)",
            amount: item.amountText,
            statusTitle: "Статус",
            statusAmount: item.statusText,
            statusStyle: statusPillStyle(for: item.statusStyle),
            isDraft: item.isDraft
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

private struct DocumentsSwipeRow<Content: View>: View {

    let onTap: () -> Void
    let onDelete: () -> Void
    let content: Content

    @State private var offset: CGFloat = 0
    @State private var dragStartOffset: CGFloat = 0
    @State private var isDraggingHorizontally = false

    private let actionWidth: CGFloat = 82

    init(
        onTap: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onTap = onTap
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteAction
                .frame(width: revealedActionWidth, alignment: .trailing)
                .clipped()
                .allowsHitTesting(revealedActionWidth >= actionWidth * 0.9)

            Button {
                if offset < 0 {
                    closeActions()
                } else {
                    onTap()
                }
            } label: {
                content
            }
            .buttonStyle(.plain)
            .offset(x: offset)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .contentShape(Rectangle())
        .simultaneousGesture(swipeGesture)
    }

    private var deleteAction: some View {
        Button(role: .destructive) {
            closeActions()
            onDelete()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16, weight: .semibold))

                Text("Удалить")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(width: actionWidth)
            .frame(maxHeight: .infinity)
            .background(Color.red)
        }
        .buttonStyle(.plain)
    }

    private var revealedActionWidth: CGFloat {
        min(actionWidth, max(0, -offset))
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                let horizontalDistance = abs(value.translation.width)
                let verticalDistance = abs(value.translation.height)
                guard horizontalDistance > verticalDistance else { return }

                if isDraggingHorizontally == false {
                    dragStartOffset = offset
                    isDraggingHorizontally = true
                }

                offset = min(0, max(-actionWidth, dragStartOffset + value.translation.width))
            }
            .onEnded { value in
                defer { isDraggingHorizontally = false }

                let horizontalDistance = abs(value.translation.width)
                let verticalDistance = abs(value.translation.height)
                guard horizontalDistance > verticalDistance else { return }

                withAnimation(.easeOut(duration: 0.18)) {
                    offset = offset < -actionWidth * 0.35 ? -actionWidth : 0
                }
            }
    }

    private func closeActions() {
        withAnimation(.easeOut(duration: 0.18)) {
            offset = 0
        }
    }
}
