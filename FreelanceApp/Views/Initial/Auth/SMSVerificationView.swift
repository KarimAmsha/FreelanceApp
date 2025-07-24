import SwiftUI
import FirebaseMessaging

struct SMSVerificationView: View {
    @Binding var loginStatus: LoginStatus
    @State private var code = ""
    @State private var totalSeconds: Int = 59
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appRouter: AppRouter
    var referalUrl: URL? = nil
    @EnvironmentObject var regViewModel: RegistrationViewModel

    private var formattedTime: String {
        String(format: "%02d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("أدخل رمز التفعيل")
                .customFont(weight: .bold, size: 20)
                .foregroundColor(.primaryBlack())

            Text(settings.user?.phone_number ?? "رقم غير معروف")
                .customFont(weight: .bold, size: 17)
                .foregroundColor(.primary())
                .frame(maxWidth: .infinity, alignment: .leading)

            OtpFormFieldView(combinedPins: $code)
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(regViewModel.state.isLoading)
                .environment(\.layoutDirection, .leftToRight)

            if code.trimmingCharacters(in: .whitespaces).count < 4 {
                Text("يجب إدخال 4 أرقام على الأقل")
                    .customFont(weight: .regular, size: 13)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            VStack(spacing: 10) {
                if totalSeconds > 0 {
                    Text("لم تستلم رمزًا؟ يمكنك إعادة الطلب بعد \(formattedTime)")
                        .customFont(weight: .regular, size: 14)
                        .foregroundColor(.grayA4ACAD())
                } else {
                    Button {
                        resendCode()
                    } label: {
                        Text(regViewModel.state.isLoading ? "جاري الإرسال..." : "طلب رمز جديد")
                            .customFont(weight: .bold, size: 15)
                            .foregroundColor(.primary())
                    }
                    .disabled(regViewModel.state.isLoading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Button("تأكيد الدخول") {
                verify()
            }
            .buttonStyle(
                GradientPrimaryButton(
                    fontSize: 16,
                    fontWeight: .bold,
                    background: Color.primaryGradientColor(),
                    foreground: .white,
                    height: 48,
                    radius: 12
                )
            )
            .disabled(code.trimmingCharacters(in: .whitespaces).count < 4 || regViewModel.state.isLoading)

            Spacer()
        }
        .padding()
        .dismissKeyboardOnTap()
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .onReceive(timer) { _ in
            if totalSeconds > 0 { totalSeconds -= 1 }
        }
        .bindLoadingState(regViewModel.state, to: appRouter)
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Actions

    private func verify() {
        guard code.trimmingCharacters(in: .whitespaces).count >= 4 else {
            appRouter.show(.error, message: "يرجى إدخال رمز التفعيل الصحيح", title: "خطأ")
            return
        }

        regViewModel.otp = code

        regViewModel.verifyPhone(verifyCode: code) {
            // بعد نجاح التحقق
            if regViewModel.isCompleteProfile {
                settings.loggedIn = true
                loginStatus = .home
            } else {
                loginStatus = .completeProfile
            }
        }
    }

    private func resendCode() {
        guard !regViewModel.state.isLoading else { return }
        guard let id = regViewModel.user?.id ?? settings.id else {
            appRouter.show(.error, message: "المعرّف غير متوفر", title: "خطأ")
            return
        }
        regViewModel.resend(id: id) {
            totalSeconds = 59
        }
    }
}


#Preview {
    SMSVerificationView(loginStatus: .constant(.verification))
        .environmentObject(UserSettings())
        .environmentObject(AppRouter())
        .environmentObject(RegistrationViewModel())
}
