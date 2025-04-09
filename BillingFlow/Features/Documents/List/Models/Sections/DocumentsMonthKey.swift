import Foundation

struct DocumentsMonthKey: Hashable {
    let year: Int
    let month: Int

    var sortValue: Int {
        year * 100 + month
    }
}
