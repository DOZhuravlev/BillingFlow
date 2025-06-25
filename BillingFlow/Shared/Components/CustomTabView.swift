import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case home
    case deals
    case createPlaceholder
    case documents
    case organizations
    case profile

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .deals: return "briefcase.fill"
        case .createPlaceholder: return "plus"
        case .documents: return "doc.text.fill"
        case .organizations: return "building.2.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}

struct CustomTabView: View {
    @Binding private var selection: AppTab
    @State private var isCreateMenuPresented = false

    private let onCreateDocument: (DocumentType) -> Void
    private let navigationTabs: [AppTab] = [.home, .deals, .documents, .organizations, .profile]

    init(selection: Binding<AppTab>, onCreateDocument: @escaping (DocumentType) -> Void) {
        _selection = selection
        self.onCreateDocument = onCreateDocument
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isCreateMenuPresented {
                createMenu
                    .padding(.bottom, 82)
                    .transition(.scale(scale: 0.72, anchor: .bottomTrailing).combined(with: .opacity))
            }

            tabBar
                .padding(.bottom, 12)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: isCreateMenuPresented)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private extension CustomTabView {
    var tabBar: some View {
        HStack(spacing: 5) {
            ForEach(navigationTabs) { tab in tabButton(tab) }

            createButton
        }
        .padding(.horizontal, 10)
        .frame(height: 58)
        .background {
            Capsule()
                .fill(.black.opacity(0.84))
                .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 10)
        }
    }

    var createButton: some View {
        Button {
            isCreateMenuPresented.toggle()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(isCreateMenuPresented ? 45 : 0))
                .frame(width: 58, height: 58)
                .background {
                    Circle()
                        .fill(Color(red: 1, green: 0.36, blue: 0.25))
                        .shadow(color: Color.red.opacity(0.38), radius: 12, x: 0, y: 6)
                }
        }
        .buttonStyle(.plain)
        .offset(y: -5)
    }

    var createMenu: some View {
        HStack(spacing: 6) {
            createMenuButton("Счет", icon: "doc.text.fill", type: .invoice)
            createMenuButton("Акт", icon: "checkmark.seal.fill", type: .act)
            createMenuButton("Фактура", icon: "doc.text.magnifyingglass", type: .deliveryNote)
        }
        .padding(8)
        .frame(width: 286)
        .background(.black.opacity(0.88), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 8)
    }

    func createMenuButton(_ title: String, icon: String, type: DocumentType) -> some View {
        Button {
            isCreateMenuPresented = false
            onCreateDocument(type)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(height: 20)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: AppRadius.sm))
        }
        .buttonStyle(.plain)
    }

    func tabButton(_ tab: AppTab) -> some View {
        Button {
            isCreateMenuPresented = false
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { selection = tab }
        } label: {
            Image(systemName: tab.icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 46)
                .background {
                    if selection == tab { Circle().fill(.white.opacity(0.12)).frame(width: 40, height: 40) }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CustomTabView(selection: .constant(.home), onCreateDocument: { _ in })
}
