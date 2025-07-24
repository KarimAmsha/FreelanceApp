import SwiftUI
import FirebaseMessaging

struct LoginView: View {
    @Binding var loginStatus: LoginStatus
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var regViewModel: RegistrationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("أدخل رقم جوالك")
                .customFont(weight: .medium, size: 18)
                .foregroundColor(.black)

            MobileView(mobile: $regViewModel.phone_number, presentSheet: .constant(false))

            PrimaryActionButton(
                title: "تسجيل الدخول",
                isLoading: regViewModel.state.isLoading
            ) {
                login()
            }
            .disabled(regViewModel.phone_number.trimmingCharacters(in: .whitespaces).count < 8)

            Spacer()
        }
        .padding()
        .background(Color.background())
        .environment(\.layoutDirection, .rightToLeft)
        .bindLoadingState(regViewModel.state, to: appRouter)
    }

    // MARK: - Actions

    private func login() {
        // 1. ابدأ بجلب الموقع
        LocationManager.shared.requestLocationOnce()

        // 2. عند تحديث الموقع، احفظه وسجل الدخول
        LocationManager.shared.onLocationUpdate = { location in
            regViewModel.lat = location.coordinate.latitude
            regViewModel.lng = location.coordinate.longitude
            regViewModel.address = LocationManager.shared.address

            regViewModel.signup(onSuccess: {
                loginStatus = .verification
            })
        }

        // 3. إذا لم يصل الموقع خلال 5 ثوانٍ، نفّذ anyway (fallback)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if regViewModel.lat == 0 && regViewModel.lng == 0 {
                regViewModel.signup(onSuccess: {
                    loginStatus = .verification
                })
            }
        }
    }
}

#Preview {
    LoginView(loginStatus: .constant(.login))
        .environmentObject(UserSettings())
        .environmentObject(AppRouter())
        .environmentObject(RegistrationViewModel())
}
