import Foundation

enum AppDateFormatter {
    static func monthYearText(_ date: Date) -> String {
        monthYearFormatter.string(from: date)
    }

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()

    static func documentDateText(_ date: Date) -> String {
        documentDateFormatter.string(from: date)
    }

    private static let documentDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()
}
