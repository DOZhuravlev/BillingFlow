import Foundation

struct DocumentsFilterChipItem: Identifiable, Equatable {
    let title: String
    let kind: Kind

    var id: Kind {
           kind
       }
}

extension DocumentsFilterChipItem {

    enum Kind: Equatable {
        case type
        case status
        case period
    }
}
