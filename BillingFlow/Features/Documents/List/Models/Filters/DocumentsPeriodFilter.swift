import Foundation

enum DocumentsPeriodFilter: CaseIterable, Identifiable, Equatable {
    case all
    case currentMonth
    case previousMonth

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            return "За всё время"

        case .currentMonth:
            return "Этот месяц"

        case .previousMonth:
            return "Прошлый месяц"
        }
    }

    func matches(_ date: Date) -> Bool {
        switch self {
        case .all:
            return true

        case .currentMonth:
            return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)

        case .previousMonth:
            guard let previousMonthDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else {
                return false
            }

            return Calendar.current.isDate(date, equalTo: previousMonthDate, toGranularity: .month)
        }
    }
}
