import SwiftUI

struct DocumentCreatePlaceholderView: View {
    let onClose: () -> Void
    let onFinish: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Создание документа")
                    .font(.title)

                Button("Завершить создание") {
                    onFinish()
                }

                Button("Закрыть") {
                    onClose()
                }
            }
            .padding()
            .navigationTitle("Новый документ")
        }
    }
}

struct PaywallPlaceholderView: View {
    let source: PaywallSource
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Paywall")
                .font(.title)

            Text("Источник: \(source.rawValue)")
                .font(.subheadline)

            Button("Закрыть") {
                onClose()
            }
        }
        .padding()
    }
}

struct OrganizationSwitcherPlaceholderView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Выбор организации")
                .font(.title)

            Button("Закрыть") {
                onClose()
            }
        }
        .padding()
    }
}

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
