import SwiftUI

enum AppFont {

    enum Display {
        static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title = Font.system(size: 22, weight: .bold, design: .rounded)
        static let sectionTitle = Font.system(size: 20, weight: .bold, design: .rounded)
    }

    enum Text {
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 15, weight: .medium, design: .rounded)
        static let subheadline = Font.system(size: 14, weight: .medium, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    }

    enum Number {
        static let largeAmount = Font.system(size: 28, weight: .bold, design: .rounded)
        static let amount = Font.system(size: 22, weight: .bold, design: .rounded)
        static let smallAmount = Font.system(size: 15, weight: .semibold, design: .rounded)
    }

    enum Control {
        static let button = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let badge = Font.system(size: 12, weight: .semibold, design: .rounded)
        static let tab = Font.system(size: 12, weight: .medium, design: .rounded)
    }
}
