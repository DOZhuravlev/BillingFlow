import Foundation

struct DocumentCardItem: Identifiable {
    let id: UUID
    let iconName: String
    let title: String
    let subtitle: String
    let amount: String
    let statusTitle: String
    let statusAmount: String
    let statusStyle: StatusPill.Style
}
