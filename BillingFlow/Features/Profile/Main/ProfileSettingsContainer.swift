import SwiftUI

struct ProfileSettingsContainer<Content: View>: View {

    let title: String
    let subtitle: String
    let onBack: (() -> Void)?
    let content: Content

    init(
        title: String,
        subtitle: String,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppColor.Brand.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if let onBack {
                    navigationBar(onBack: onBack)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        if let _ = onBack {
                            if subtitle.isEmpty == false {
                                Text(subtitle)
                                    .font(AppFont.Text.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } else {
                            header
                        }

                        content
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppLayout.floatingTabBarBottomInset)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private func navigationBar(onBack: @escaping () -> Void) -> some View {
        HStack(spacing: AppSpacing.md) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.16), in: Circle())
            }
            .buttonStyle(.plain)

            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(AppFont.Text.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
