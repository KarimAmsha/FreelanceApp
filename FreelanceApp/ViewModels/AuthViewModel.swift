import Foundation
import SwiftUI
import Combine
import Alamofire

@MainActor
class AuthViewModel: ObservableObject, GenericAPILoadable {
    // MARK: - Published
    @Published var state: LoadingState = .idle
    var appRouter: AppRouter?
    @Published var user: User?
    @Published var mobile: String = ""
    @Published var loggedIn: Bool = false
    @Published var showErrorPopup: Bool = false

    // MARK: - Computed
    var isLoading: Bool { state.isLoading }
    var isSuccess: Bool { state.isSuccess }
    var isFailure: Bool { state.isFailure }
    var errorMessage: String? { state.message }

    private let settings = UserSettings.shared
    private var token: String? { settings.token }

    private func tokenGuard() -> Bool {
        guard token != nil else {
            failLoading(error: "Token غير متوفر")
            return false
        }
        return true
    }

    // MARK: - Register
    func registerUser(body: SignupRequest, onsuccess: @escaping (String, String) -> Void) {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .register(body: body), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            guard let self = self else { return }
            guard let user = response.items else {
                self.failLoading(error: "فشل في إنشاء الحساب")
                return
            }
            self.user = user
            self.handleVerificationStatus(isVerified: user.isVerify ?? false)
            self.finishLoading()
            onsuccess(user.id ?? "", user.token ?? "")
        }
    }

    // MARK: - Verify
    func verify(body: VerifyRequest, onsuccess: @escaping (Bool, String) -> Void, onError: @escaping (String) -> Void) {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .verify(body: body), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            guard let self = self else { return }
            guard let user = response.items else {
                self.failLoading(error: "فشل في التحقق من الرقم")
                onError("فشل في قراءة البيانات")
                return
            }
            self.user = user
            self.settings.token = user.token
            self.finishLoading()
            onsuccess(user.isCompleteProfile ?? false, user.token ?? "")
        }
    }

    func resend(body: ResendRequest, onsuccess: @escaping () -> Void, onError: @escaping (String) -> Void) {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .resend(body: body), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            guard let self = self else { return }
            guard let user = response.items else {
                self.failLoading(error: "فشل في إعادة إرسال الرمز")
                onError("فشل في إعادة إرسال الرمز")
                return
            }
            self.user = user
            self.handleVerificationStatus(isVerified: user.isVerify ?? false)
            self.finishLoading()
            onsuccess()
        }
    }

    // MARK: - Logout
    func logoutUser(onsuccess: @escaping () -> Void) {
        guard tokenGuard() else { return }
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .logout(userID: settings.id ?? "", token: token!), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            self?.user = response.items
            self?.settings.logout()
            self?.finishLoading()
            onsuccess()
        }
    }

    // MARK: - Delete Account
    func deleteAccount(onsuccess: @escaping () -> Void) {
        guard tokenGuard() else { return }
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .deleteAccount(id: settings.id ?? "", token: token!), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            self?.user = response.items
            self?.settings.logout()
            self?.finishLoading()
            onsuccess()
        }
    }

    // MARK: - Guest
    func guest(onsuccess: @escaping () -> Void) {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .guest, responseType: CustomApiResponse.self) { [weak self] response in
            if let token = response.items {
                self?.settings.guestLogin(token: token)
                self?.finishLoading()
                onsuccess()
            } else {
                self?.failLoading(error: "فشل تسجيل الدخول كزائر")
            }
        }
    }

    // MARK: - Helpers
    func handleVerificationStatus(isVerified: Bool) {
        if isVerified, let user = self.user {
            settings.login(user: user, id: user.id ?? "", token: user.token ?? "")
        }
    }

    func reset() {
        state = .idle
        mobile = ""
        loggedIn = false
        user = nil
        showErrorPopup = false
    }
}

struct ResendRequest: Encodable {
    let phone_number: String
}
