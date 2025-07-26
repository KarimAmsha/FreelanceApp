//
//  PhoneChangeViewModel.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 24.07.2025.
//

import SwiftUI
import Combine
import Alamofire

struct EditPhoneRequest: Encodable {
    let id: String
    let phone_number: String
}

@MainActor
class PhoneChangeViewModel: ObservableObject, GenericAPILoadable {

    @Published var state: LoadingState = .idle
    var appRouter: AppRouter?
    var isLoading: Bool { state.isLoading }
    var errorMessage: String? { state.message }

    // MARK: - Inputs
    @Published var oldPhone = UserSettings.shared.user?.phone_number ?? ""
    @Published var oldOtp = ""
    @Published var newPhone = ""
    @Published var newOtp = ""

    @Published var countryCode = "+966"
    @Published var countryFlag = "🇸🇦"

    // MARK: - Steps
    @Published var step: PhoneChangeStep = .enterOldPhone
    @Published var showOldOtpPopup = false
    @Published var showNewOtpPopup = false

    // MARK: - Timer
    @Published var timer: Int = 59
    @Published var canResend = false
    private var timerCancellable: AnyCancellable?

    // MARK: - Current User
    @Published var user: User? = UserSettings.shared.user

    func requestOldOtp() {
        startLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.showOldOtpPopup = true
            self.startTimer()
            self.finishLoading()
        }
    }

    func verifyOldOtp(onSuccess: @escaping () -> Void) {
        guard let id = user?.id else {
            failLoading(error: "معرّف المستخدم غير متوفر")
            return
        }
        guard shouldStartLoading() else { return }
        startLoading()

        let request = VerifyRequest(
            id: id,
            verify_code: oldOtp,
            phone_number: getFullPhone(oldPhone)
        )

        fetchAPI(endpoint: .verify(body: request), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            self?.showOldOtpPopup = false
            self?.step = .enterNewPhone
            self?.finishLoading()
            onSuccess()
        }
    }

    func updateNewPhone(onSuccess: @escaping () -> Void) {
        guard tokenGuard(UserSettings.shared.token) else { return }
        guard let id = user?.id else {
            failLoading(error: "معرّف المستخدم غير متوفر")
            return
        }
        guard shouldStartLoading() else { return }
        startLoading()

        let request = EditPhoneRequest(id: id, phone_number: getFullPhone(newPhone))

        fetchAPI(endpoint: .editPhone(body: request, token: UserSettings.shared.token!), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            self?.showNewOtpPopup = true
            self?.startTimer()
            self?.finishLoading()
            onSuccess()
        }
    }

    func verifyNewOtp(onSuccess: @escaping () -> Void) {
        guard let id = user?.id else {
            failLoading(error: "معرّف المستخدم غير متوفر")
            return
        }
        guard shouldStartLoading() else { return }
        startLoading()

        let request = VerifyRequest(
            id: id,
            verify_code: newOtp,
            phone_number: getFullPhone(newPhone)
        )

        fetchAPI(endpoint: .verify(body: request), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            guard let updatedUser = response.items else {
                self?.failLoading(error: "فشل التحقق من الهاتف الجديد")
                return
            }
            self?.user = updatedUser
            UserSettings.shared.user = updatedUser
            self?.showNewOtpPopup = false
            self?.step = .success
            self?.finishLoading()
            onSuccess()
        }
    }

    func resend(id: String, onSuccess: @escaping () -> Void) {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .resend(body: ["id": id]), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            self?.startTimer()
            self?.finishLoading()
            onSuccess()
        }
    }

    func getFullPhone(_ phone: String) -> String {
        let code = countryCode.replacingOccurrences(of: "+", with: "")
        var number = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if number.hasPrefix(code) {
            number = String(number.dropFirst(code.count))
        }
        return code + number
    }

    func startTimer() {
        timerCancellable?.cancel()
        timer = 59
        canResend = false

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timer > 0 {
                    self.timer -= 1
                }
                if self.timer == 0 {
                    self.canResend = true
                    self.timerCancellable?.cancel()
                }
            }
    }

    func reset() {
        oldPhone = ""
        oldOtp = ""
        newPhone = ""
        newOtp = ""
        timer = 59
        canResend = false
        showOldOtpPopup = false
        showNewOtpPopup = false
        step = .enterOldPhone
        state = .idle
    }
    
    // MARK: - حماية التوكن
    private func tokenGuard(_ token: String?) -> Bool {
        guard let token = token, !token.isEmpty else {
            failLoading(error: "Token غير متوفر")
            return false
        }
        return true
    }
    
    // MARK: - إعادة إرسال الكود
    func resendOldOtp() {
        guard let id = user?.id else {
            failLoading(error: "معرّف المستخدم غير متوفر")
            return
        }

        fetchAPI(
            endpoint: .resend(body: ["id": id]),
            responseType: SingleAPIResponse<User>.self
        ) { [weak self] _ in
            self?.startTimer()
        }
    }

    func resendNewOtp() {
        resendOldOtp()
    }
    
    func getOldPhoneWithoutCode() -> String {
        let full = UserSettings.shared.user?.phone_number ?? ""
        let code = countryCode.replacingOccurrences(of: "+", with: "")
        var number = full.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        if number.hasPrefix(code) {
            number = String(number.dropFirst(code.count))
        }

        return number
    }
}

enum PhoneChangeStep {
    case enterOldPhone
    case verifyOldPhone
    case enterNewPhone
    case verifyNewPhone
    case success
}
