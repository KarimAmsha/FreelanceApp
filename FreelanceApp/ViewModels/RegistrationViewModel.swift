//
//  RegistrationViewModel.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 24.07.2025.
//

import SwiftUI
import Combine
import Alamofire
import Foundation
import FirebaseMessaging

// MARK: - Request Structs

struct SignupRequest: Encodable {
    let phone_number: String
    let os: String
    let fcmToken: String
    let lat: Double
    let lng: Double
    let register_type: String
    let app_type: String
}

struct ProfileRequest: Encodable {
    let email: String
    let full_name: String
    let lat: Double
    let lng: Double
    let reg_no: String?
    let address: String
    let dob: String?
    let category: String?
    let bio: String
    let image: String
    let id_image: String
    let subcategory: String?
    let register_type: String
}

struct VerifyRequest: Encodable {
    let id: String
    let verify_code: String
    let phone_number: String
}

// MARK: - ViewModel

@MainActor
class RegistrationViewModel: ObservableObject, GenericAPILoadable {

    @Published var state: LoadingState = .idle
    var appRouter: AppRouter?
    var isLoading: Bool { state.isLoading }
    var errorMessage: String? { state.message }

    @Published var user: User?
    @Published var selectedRole: UserRole? = nil
    var isCompleteProfile: Bool { user?.isCompleteProfile ?? false }

    // MARK: - Inputs
    @Published var phone_number = ""
    @Published var countryCode = "966"
    @Published var os = "IOS"
    @Published var fcmToken = ""
    @Published var lat = 0.0
    @Published var lng = 0.0
    @Published var app_type = "customer"
    @Published var otp = ""
    @Published var isPhoneVerified = false

    // MARK: - Profile Info
    @Published var email = ""
    @Published var full_name = ""
    @Published var address = ""
    @Published var dob = ""
    @Published var bio = ""
    @Published var reg_no = ""
    @Published var country = ""
    @Published var city = ""
    @Published var work = ""
    @Published var subcategory: String? = nil
    @Published var mainCategoryId: String? = nil

    // MARK: - Media
    @Published var imageURL: String? = nil
    @Published var idImageURL: String? = nil

    // MARK: - Categories
    @Published var allCategories: [Category] = []
    @Published var allTypes: [TypeItem] = []

    func getMissingProfileField(
        skipImageValidation: Bool = false,
        skipCategory: Bool = false
    ) -> String? {
        guard let role = selectedRole else { return "نوع الحساب غير محدد" }

        let requiredFields: [(String, String)] = [
            (email, "البريد الإلكتروني مطلوب"),
            (full_name, "الاسم الكامل مطلوب"),
            (bio, "نبذة عنك مطلوبة"),
            (address, "العنوان مطلوب")
        ]

        for (field, message) in requiredFields {
            if field.trimmed.isEmpty { return message }
        }

        if lat == 0.0 || lng == 0.0 {
            return "الموقع الجغرافي غير محدد"
        }

        if !skipImageValidation {
            if imageURL.orEmpty.isEmpty { return "الصورة الشخصية مطلوبة" }
            if idImageURL.orEmpty.isEmpty { return "صورة الهوية مطلوبة" }
        }

        switch role {
        case .personal:
            if dob.trimmed.isEmpty { return "تاريخ الميلاد مطلوب" }

            if !skipCategory {
                if mainCategoryId?.trimmed.isEmpty != false { return "التخصص الرئيسي مطلوب" }
                if subcategory.orEmpty.trimmed.isEmpty { return "الاختصاص الفرعي مطلوب" }
            }

        case .company:
            if reg_no.trimmed.isEmpty { return "رقم السجل التجاري مطلوب" }
        case .none:
            return "نوع الحساب غير مدعوم"
        }

        return nil
    }

    // MARK: - Actions

    func signup(onSuccess: @escaping () -> Void) {
        guard shouldStartLoading() else { return }
        startLoading()
        let request = toSignupRequest()

        fetchAPI(endpoint: .register(body: request), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            print("🚨 Response:", response)

            guard let user = response.items else {
                self?.failLoading(error: "فشل في استلام بيانات المستخدم")
                return
            }

            self?.user = user
            UserSettings.shared.user = user
            UserSettings.shared.id = user.id
            self?.finishLoading()
            onSuccess()
        }
    }

    func verifyPhone(verifyCode: String, onSuccess: @escaping () -> Void) {
        guard let request = toVerifyRequest(verifyCode: verifyCode) else {
            failLoading(error: "معرّف المستخدم غير متوفر")
            return
        }
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .verify(body: request), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            guard let user = response.items else {
                self?.failLoading(error: "فشل التحقق من الهاتف")
                return
            }
            self?.user = user
            self?.isPhoneVerified = true
            self?.handleUser(user)
            self?.finishLoading()
            onSuccess()
        }
    }

    func resend(id: String, onSuccess: @escaping () -> Void) {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .resend(body: ["id": id]), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            self?.user = response.items
            self?.finishLoading()
            onSuccess()
        }
    }

    func updateProfile(onSuccess: @escaping () -> Void) {
        guard tokenGuard(UserSettings.shared.token) else { return }
        guard shouldStartLoading() else { return }
        startLoading()
        let request = toProfileRequest()

        fetchAPI(endpoint: .updateUserData(body: request, token: UserSettings.shared.token!), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            guard let user = response.items else {
                self?.failLoading(error: "فشل تحديث البيانات")
                return
            }
            self?.handleUser(user)
            self?.finishLoading()
            onSuccess()
        }
    }

    func getMainCategories(completion: (() -> Void)? = nil) {
        fetchAPI(endpoint: .getCategories, responseType: SingleAPIResponse<CategoriesItems>.self) { [weak self] response in
            self?.allCategories = response.items?.category ?? []
            completion?()
        }
    }

    func getMainCategories() {
        fetchAPI(endpoint: .getCategories, responseType: SingleAPIResponse<CategoriesItems>.self) { [weak self] response in
            self?.allCategories = response.items?.category ?? []
            self?.allTypes = response.items?.type ?? []
        }
    }

    func fetchUserProfile(onComplete: (() -> Void)? = nil) {
        guard let token = UserSettings.shared.token, !token.isEmpty else { return }
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .getUserProfile(token: token), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            guard let user = response.items else {
                self?.failLoading(error: "لم يتم العثور على بيانات المستخدم")
                onComplete?()
                return
            }
            self?.fillInputs(from: user)
            self?.handleUser(user)
            self?.finishLoading()
            onComplete?()
        }
    }

    func login(onSuccess: @escaping (User) -> Void, onError: @escaping (String) -> Void) {
        guard shouldStartLoading() else { return }
        startLoading()
        let request = toSignupRequest()

        fetchAPI(endpoint: .register(body: request), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            guard let self = self else { return }
            guard let user = response.items else {
                self.failLoading(error: "فشل في تسجيل الدخول")
                onError("فشل في تسجيل الدخول")
                return
            }
            UserSettings.shared.login(user: user, id: user.id ?? "", token: user.token ?? "")
            self.user = user
            self.finishLoading()
            onSuccess(user)
        }
    }

    // MARK: - Helpers

    private func handleUser(_ user: User) {
        self.user = user

        if let type = user.register_type, let role = UserRole(rawValue: type) {
            selectedRole = role
        }
//        else {
//            failLoading(error: "نوع الحساب غير معروف. يرجى إعادة تسجيل الحساب.")
//            return
//        }

        if user.isCompleteProfile == true {
            UserSettings.shared.login(user: user, id: user.id ?? "", token: user.token ?? "")
        } else {
            UserSettings.shared.setIncompleteProfile(user: user, id: user.id ?? "", token: user.token ?? "")
        }
    }

    func getCompletePhoneNumber() -> String {
        let cleanedMobile = phone_number.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: "")
        let cleanedCode = countryCode.replacingOccurrences(of: "+", with: "")
        return cleanedMobile.hasPrefix(cleanedCode) ? cleanedMobile : "\(cleanedCode)\(cleanedMobile)"
    }

    func toSignupRequest() -> SignupRequest {
        SignupRequest(
            phone_number: getCompletePhoneNumber(),
            os: os,
            fcmToken: fcmToken,
            lat: lat,
            lng: lng,
            register_type: isCompleteProfile ? (user?.register_type ?? "") : (selectedRole?.rawValue ?? ""),
            app_type: app_type
        )
    }

    func toVerifyRequest(verifyCode: String) -> VerifyRequest? {
        guard let id = user?.id else { return nil }
        return VerifyRequest(id: id, verify_code: verifyCode, phone_number: getCompletePhoneNumber())
    }

    func toProfileRequest() -> ProfileRequest {
        ProfileRequest(
            email: email.trimmed,
            full_name: full_name.trimmed,
            lat: lat,
            lng: lng,
            reg_no: selectedRole == .company ? reg_no.trimmed : nil,
            address: address.trimmed,
            dob: selectedRole == .personal ? dob.trimmed : nil,
            category: selectedRole == .personal ? mainCategoryId?.trimmed : nil,
            bio: bio.trimmed,
            image: imageURL.orEmpty,
            id_image: idImageURL.orEmpty,
            subcategory: selectedRole == .personal ? subcategory?.trimmed : nil,
            register_type: selectedRole?.rawValue ?? "personal"
        )
    }

    private func tokenGuard(_ token: String?) -> Bool {
        guard let token = token, !token.isEmpty else {
            failLoading(error: "Token غير متوفر")
            return false
        }
        return true
    }

    func reset() {
        phone_number = ""
        countryCode = "966"
        os = "IOS"
        fcmToken = ""
        lat = 0.0
        lng = 0.0
        app_type = "customer"
        otp = ""
        isPhoneVerified = false
        email = ""
        full_name = ""
        address = ""
        dob = ""
        bio = ""
        reg_no = ""
        country = ""
        city = ""
        work = ""
        subcategory = ""
        mainCategoryId = nil
        imageURL = nil
        idImageURL = nil
        allCategories = []
        allTypes = []
        state = .idle
        user = nil
        selectedRole = nil
    }

    func fillInputs(from user: User) {
        self.user = user
        self.phone_number = user.phone_number ?? ""
        self.email = user.email ?? ""
        self.full_name = user.full_name ?? ""
        self.address = user.address ?? ""
        self.dob = user.dob ?? ""
        self.bio = user.bio ?? ""
        self.reg_no = user.reg_no ?? ""
        self.country = user.country ?? ""
        self.city = user.city ?? ""
        self.work = user.work ?? ""
        self.subcategory = user.subcategory ?? ""
        self.mainCategoryId = user.category
        self.imageURL = user.image
        self.idImageURL = user.id_image
        self.selectedRole = UserRole(rawValue: user.register_type ?? "")
        self.isPhoneVerified = user.isVerify ?? false
        self.lat = user.lat ?? 0.0
        self.lng = user.lng ?? 0.0
    }
}

extension RegistrationViewModel {
    func restoreIfNeeded(using router: AppRouter) {
        if state != .idle { return }

        self.appRouter = router

        Messaging.messaging().token { token, _ in
            if let token = token {
                self.fcmToken = token
            }
        }

        if let localUser = UserSettings.shared.user {
            fillInputs(from: localUser)
            resetState()
        }
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Optional where Wrapped == String {
    var orEmpty: String {
        self?.trimmed ?? ""
    }
}
