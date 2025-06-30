import SwiftUI

struct PhoneAuthScreen: View {
    private enum Step {
        case phone
        case code
    }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authController: AuthController

    @State private var step: Step = .phone
    @State private var phone = ""
    @State private var code = ""
    @State private var challenge: PhoneChallenge?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColor.Brand.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        titleSection
                        inputCard
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.lg)
                }

                actionButton
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.md)
            }
        }
        .interactiveDismissDisabled(isLoading)
    }
}

private extension PhoneAuthScreen {
    var navigationBar: some View {
        HStack {
            Button(action: backOrDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Вход")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.sm)
    }

    var titleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(step == .phone ? "Введите номер телефона" : "Введите код")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text(step == .phone ? "Номер станет идентификатором вашего аккаунта" : "Тестовый код: 1234")
                .font(AppFont.Text.body)
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    var inputCard: some View {
        MaterialCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(step == .phone ? "Телефон" : "Код подтверждения")
                    .font(AppFont.Text.caption)
                    .foregroundStyle(AppColor.Text.secondary)

                if step == .phone {
                    TextField("+7 999 123-45-67", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                } else {
                    TextField("1234", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppFont.Text.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    var actionButton: some View {
        Button(action: submit) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(step == .phone ? "Получить код" : "Войти")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppColor.Brand.primary, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading || isInputValid == false)
        .opacity(isInputValid ? 1 : 0.45)
    }

    var isInputValid: Bool {
        switch step {
        case .phone:
            return phone.filter(\.isNumber).count >= 10
        case .code:
            return code.count >= 4
        }
    }

    func backOrDismiss() {
        if step == .code {
            step = .phone
            code = ""
            errorMessage = nil
        } else {
            dismiss()
        }
    }

    func submit() {
        guard isLoading == false else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                switch step {
                case .phone:
                    challenge = try await authController.requestCode(phone: phone)
                    step = .code
                case .code:
                    guard let challenge else {
                        errorMessage = "Запросите новый код."
                        isLoading = false
                        return
                    }
                    try await authController.verify(challengeID: challenge.challengeId, code: code)
                    dismiss()
                }
            } catch {
#if DEBUG
                print("[Auth] Request failed:", error)
#endif
                errorMessage = step == .code
                    ? "Неверный или устаревший код."
                    : error.localizedDescription
            }
            isLoading = false
        }
    }
}
