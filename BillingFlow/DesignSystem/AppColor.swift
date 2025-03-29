import SwiftUI

enum AppColor {

    enum Text {
        static let primary = Color.black.opacity(0.88)
        static let secondary = Color.black.opacity(0.56)
        static let tertiary = Color.black.opacity(0.34)
        static let inverse = Color.white
    }

    enum Brand {
        static let primary = Color("brandPrimary")
        static let secondary = Color("brandSecondary")
        static let background = LinearGradient(colors: [primary, secondary], startPoint: .top, endPoint: .bottom)
    }

    enum Status {
        static let success = Color("statusSuccess")
        static let successBackground = Color("statusSuccessBackground")
        static let danger = Color("statusDanger")
        static let dangerBackground = Color("statusDangerBackground")
    }
}
