import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case home
    case documents
    case createPlaceholder
    case counterparties
    case more

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .home:
            "house"
        case .documents:
            "chart.line.uptrend.xyaxis"
        case .createPlaceholder:
            "plus"
        case .counterparties:
            "person.2.fill"
        case .more:
            "ellipsis"
        }
    }
}

struct CustomTabView: View {
    @Binding private var selection: AppTab

    private let onCreateTap: () -> Void
    private let leftTabs: [AppTab] = [
        .home,
        .documents
    ]
    private let rightTabs: [AppTab] = [
        .counterparties,
        .more
    ]

    init(
        selection: Binding<AppTab>,
        onCreateTap: @escaping () -> Void,
    ) {
        _selection = selection
        self.onCreateTap = onCreateTap
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabBar
                .padding(.bottom, 12)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private extension CustomTabView {
    var tabBar: some View {
        HStack(spacing: 10) {
            ForEach(leftTabs) { tab in
                tabButton(tab)
            }

            createButton

            ForEach(rightTabs) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 58)
        .background {
            Capsule()
                .fill(.black.opacity(0.82))
                .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 10)
        }
    }
    var createButton: some View {
        Button {
            onCreateTap()
        } label: {
            Image(systemName: AppTab.createPlaceholder.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.48, blue: 0.32),
                                    Color(red: 1.0, green: 0.32, blue: 0.24)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: Color(red: 1.0, green: 0.35, blue: 0.22).opacity(0.45),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                }
        }
        .buttonStyle(.plain)
        .offset(y: -5)
    }

    func tabButton(_ tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selection = tab
            }
        } label: {
            Image(systemName: tab.icon)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background {
                    if selection == tab {
                        Circle()
                            .fill(.white.opacity(0.12))
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct PreviewCustomTabView: View {
    @State private var selection: AppTab = .home
    @State private var isCreatePresented = false

    var body: some View {
        CustomTabView(
            selection: $selection,
            onCreateTap: {
                isCreatePresented = true
            }
        )
        .sheet(isPresented: $isCreatePresented) {
            Text("Создание документа")
                .font(.title)
        }
    }
}

#Preview {
    PreviewCustomTabView()
}
