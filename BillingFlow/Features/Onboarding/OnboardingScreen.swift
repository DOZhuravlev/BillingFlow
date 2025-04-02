import SwiftUI

struct OnboardingPlaceholderView: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Онбординг")
                .font(.title)

            Button("Начать") {
                onFinish()
            }
        }
        .padding()
    }
}
