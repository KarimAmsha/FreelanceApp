import SwiftUI

struct ConfirmPhoneView: View {
    @ObservedObject var regViewModel: RegistrationViewModel
    @State private var totalSeconds: Int = 59
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var isResending: Bool = false
    @State private var errorMessage: String? = nil

    var onComplete: (() -> Void)? = nil

    @EnvironmentObject var appState: AppState

    var formattedTime: String {
        String(format: "0:%02d", totalSeconds % 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            RegistrationStepHeader(
                title: "تأكيد رقم الجوال",
                subtitle: "أدخل رمز التفعيل المرسل إلى رقمك."
            )

            Text(regViewModel.getCompletePhoneNumber())
                .customFont(weight: .bold, size: 17)
                .foregroundColor(.primary())
                .frame(maxWidth: .infinity, alignment: .leading)

            OtpFormFieldView(combinedPins: $regViewModel.otp)
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(isResending)
                .environment(\..layoutDirection, .leftToRight)

            VStack(spacing: 10) {
                if totalSeconds > 0 {
                    Text("لم تستلم رمزًا؟ يمكنك إعادة الطلب بعد \(formattedTime)")
                        .customFont(weight: .regular, size: 14)
                        .foregroundColor(.grayA4ACAD())
                } else {
                    Button {
                        resendCode()
                    } label: {
                        Text(isResending ? "جاري الإرسال..." : "طلب رمز جديد")
                            .customFont(weight: .bold, size: 15)
                            .foregroundColor(.primary())
                    }
                    .disabled(isResending)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)

            Spacer()
        }
        .padding()
        .dismissKeyboardOnTap()
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .onReceive(timer) { _ in
            if totalSeconds > 0 {
                totalSeconds -= 1
            }
        }
        .overlay(
            VStack {
                if let errorMessage = errorMessage {
                    MessageAlertView(message: errorMessage)
                }
            }
        )
        .environment(\..layoutDirection, .rightToLeft)
    }

    private func resendCode() {
        guard !isResending else { return }
        isResending = true

        let userId = UserSettings.shared.id ?? ""
        regViewModel.resend(id: userId) {
            totalSeconds = 59
            isResending = false
        }
    }
}

#Preview {
    ConfirmPhoneView(regViewModel: RegistrationViewModel())
        .environmentObject(AppState())
}
