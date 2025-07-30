import SwiftUI
import FirebaseMessaging
import CoreLocation

struct LoginView: View {
    @Binding var loginStatus: LoginStatus
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var regViewModel: RegistrationViewModel

    @State private var hasLocationBeenSet = false

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

    // MARK: - Login Logic
    private func login() {
        let manager = LocationManager.shared
        hasLocationBeenSet = false

        // نطلب الموقع
        manager.requestLocationOnce()

        // بعد طلب الإذن مباشرة، ننتظر 1 ثانية ثم نتحقق من الحالة
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let status = manager.authorizationStatus
            if status == .denied || status == .restricted {
                appRouter.showAlert(
                    title: "صلاحية الموقع مرفوضة",
                    message: "يرجى تفعيل الموقع من الإعدادات لتسجيل الدخول.",
                    okTitle: "فتح الإعدادات"
                ) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                return
            }

            // ✅ إذا الإذن مسموح نكمل
            manager.onLocationUpdate = { location in
                setLocationData(
                    lat: location.coordinate.latitude,
                    lng: location.coordinate.longitude
                )
                if !hasLocationBeenSet {
                    hasLocationBeenSet = true
                    proceedWithSignup()
                }
            }

            // Fallback بعد 5 ثواني
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if !hasLocationBeenSet {
                    hasLocationBeenSet = true
                    setLocationData(
                        lat: 24.7136,
                        lng: 46.6753,
                        address: "📍 الموقع غير محدد - تم التعيين تلقائيًا"
                    )
                    proceedWithSignup()
                }
            }
        }
    }

    private func setLocationData(lat: Double, lng: Double, address: String? = nil) {
        regViewModel.lat = lat
        regViewModel.lng = lng
        regViewModel.address = address ?? LocationManager.shared.address
    }

    private func proceedWithSignup() {
        regViewModel.signup(onSuccess: {
            loginStatus = .verification
        })
    }
}
