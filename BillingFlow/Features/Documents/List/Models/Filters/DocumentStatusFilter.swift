import Foundation
import SwiftUI

enum DocumentStatusFilter: CaseIterable, Identifiable, Equatable {
    case all
    case drafts
    case ready
    case shared

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            return "Все"
        case .drafts:
            return "Черновики"
        case .ready:
            return "Готовые"
        case .shared:
            return "Отправленные"
        }
    }

    var dotColor: Color? {
        switch self {
        case .all:
            return nil
        case .drafts:
            return .gray
        case .ready:
            return .green
        case .shared:
            return .orange
        }
    }

    func matches(_ document: BusinessDocument) -> Bool {
        switch self {
        case .all:
            return true
        case .drafts:
            return document.status == .draft
        case .ready:
            return document.status == .ready
        case .shared:
            return document.status == .shared
        }
    }
}
