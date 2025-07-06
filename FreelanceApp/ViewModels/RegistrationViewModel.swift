//
//  RegistrationViewModel.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 24.06.2025.
//

import SwiftUI
import Combine

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
    let address: String?
    let country: String?
    let city: String?
    let dob: String?
    let category: String?
    let subcategory: String?
    let work: String?
    let bio: String?
    let image: String?
    let id_img: String?
}

class RegistrationViewModel: ObservableObject {
    @Published var selectedRole: UserRole? = .company

    // الحقول الأساسية
    @Published var phone_number: String = ""
    @Published var os: String = "IOS"
    @Published var fcmToken: String = ""
    @Published var lat: Double = 0.0
    @Published var lng: Double = 0.0
    @Published var app_type: String = "customer"

    // الحقول الشخصية
    @Published var email: String = ""
    @Published var full_name: String = ""
    @Published var address: String = ""
    @Published var dob: String = ""
    @Published var bio: String = ""
    @Published var imageURL: String? = nil
    @Published var idImageURL: String? = nil

    // حقل الشركة فقط
    @Published var reg_no: String = ""

    // الحقول المشتركة والإضافية
    @Published var country: String = ""
    @Published var city: String = ""
    @Published var work: String = ""        // sector/type id
    @Published var subcategory: String = "" // subcategory id

    // التخصصات
    @Published var allCategories: [Category] = []
    @Published var allTypes: [TypeItem] = []
    @Published var mainCategoryId: String? = nil   // category id (التخصص الرئيسي)

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    private let errorHandling: ErrorHandling
    @Published var user: User?
    @Published var isPhoneVerified: Bool = false
    @Published var otp: String = ""
    @Published var countryCode: String = "966" // الكود الافتراضي

    var register_type: String {
        selectedRole?.rawValue ?? ""
    }

    init(errorHandling: ErrorHandling) {
        self.errorHandling = errorHandling
    }

    // MARK: - Build Request Structs

    func toSignupRequest() -> SignupRequest {
        SignupRequest(
            phone_number: getCompletePhoneNumber(),
            os: os,
            fcmToken: fcmToken,
            lat: lat,
            lng: lng,
            register_type: selectedRole?.rawValue ?? "",
            app_type: app_type
        )
    }

    func toProfileRequest() -> ProfileRequest {
        ProfileRequest(
            email: email,
            full_name: full_name,
            lat: lat,
            lng: lng,
            reg_no: selectedRole == .company ? (reg_no.isEmpty ? nil : reg_no) : nil,
            address: address.isEmpty ? nil : address,
            country: country.isEmpty ? nil : country,
            city: city.isEmpty ? nil : city,
            dob: selectedRole == .personal ? (dob.isEmpty ? nil : dob) : nil,
            category: selectedRole == .personal ? mainCategoryId : nil,
            subcategory: subcategory.isEmpty ? nil : subcategory,
            work: work.isEmpty ? nil : work,
            bio: bio.isEmpty ? nil : bio,
            image: imageURL,
            id_img: idImageURL
        )
    }

    func toVerifyRequest(verifyCode: String) -> VerifyRequest? {
        guard let id = user?.id else { return nil }
        return VerifyRequest(
            id: id,
            verify_code: verifyCode,
            phone_number: getCompletePhoneNumber()
        )
    }

    // MARK: - API Methods

    func signup(completion: @escaping (Result<User, Error>) -> Void) {
        errorMessage = nil
        let request = toSignupRequest()
        DataProvider.shared.sendRequest(
            endpoint: .register(params: request.asDictionary() ?? [:]),
            body: request,
            responseType: SingleAPIResponse<User>.self
        ) { result in
            switch result {
            case .success(let apiResponse):
                if apiResponse.status, let user = apiResponse.items {
                    self.user = user
                    print("ssss \(user)")
                    if !(user.full_name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.handleUserData()
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .didLoginSuccessfully, object: nil)
                        }
                    }
                    completion(.success(user))
                } else {
                    self.errorMessage = apiResponse.message
                    completion(.failure(APIClient.APIError.customError(message: apiResponse.message)))
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
        }
    }

    func updateProfile(completion: @escaping (Result<User, Error>) -> Void) {
        errorMessage = nil
        let request = toProfileRequest()
        guard let token = UserSettings.shared.token else {
            completion(.failure(APIClient.APIError.unauthorized))
            return
        }
        DataProvider.shared.sendRequest(
            endpoint: .updateUserData(params: request.asDictionary() ?? [:], token: token),
            body: request,
            responseType: SingleAPIResponse<User>.self
        ) { result in
            switch result {
            case .success(let apiResponse):
                if apiResponse.status, let user = apiResponse.items {
                    self.user = user
                    self.handleUserData()
                    self.errorMessage = nil
                    completion(.success(user))
                } else {
                    self.errorMessage = apiResponse.message
                    completion(.failure(APIClient.APIError.customError(message: apiResponse.message)))
                }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
        }
    }

    func verifyPhone(verifyCode: String, completion: @escaping (Result<User, Error>) -> Void) {
        errorMessage = nil
        isLoading = true
        guard let request = toVerifyRequest(verifyCode: verifyCode) else {
            let err = APIClient.APIError.customError(message: "معرّف المستخدم غير متوفر")
            self.errorMessage = err.localizedDescription
            completion(.failure(err))
            return
        }
        DataProvider.shared.sendRequest(
            endpoint: .verify(params: request.asDictionary() ?? [:]),
            body: request,
            responseType: SingleAPIResponse<User>.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let apiResponse):
                    if apiResponse.status, let user = apiResponse.items {
                        self?.isPhoneVerified = true
                        self?.user = user
                        self?.handleUserData()
                        self?.errorMessage = nil
                        completion(.success(user))
                    } else {
                        let err = APIClient.APIError.customError(message: apiResponse.message)
                        self?.errorMessage = err.localizedDescription
                        completion(.failure(err))
                    }
                case .failure(let error):
                    if let apiError = error as? APIClient.APIError {
                        self?.errorMessage = apiError.localizedDescription
                        completion(.failure(apiError))
                    } else {
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Fetch Categories

    func getMainCategories() {
        isLoading = true
        errorMessage = nil
        let endpoint = DataProvider.Endpoint.getCategories
        DataProvider.shared.request(endpoint: endpoint, responseType: CategoriesResponse.self)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error): self.handleAPIError(error)
                }
            }, receiveValue: { [weak self] response in
                if response.status, let items = response.items {
                    self?.allCategories = items.category
                    self?.allTypes = items.type
                } else {
                    self?.handleAPIError(.customError(message: response.message ?? ""))
                }
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }

    // MARK: - Error Handling

    private func handleAPIError(_ error: APIClient.APIError) {
        let errorDescription = errorHandling.handleAPIError(error)
        errorMessage = errorDescription
    }

    func handleUserData() {
        if let user = self.user {
            UserSettings.shared.login(user: user, id: user.id ?? "", token: user.token ?? "")
        }
    }

    func reset() {
        selectedRole = nil
        phone_number = ""
        os = "IOS"
        fcmToken = ""
        lat = 0.0
        lng = 0.0
        app_type = "customer"
        email = ""
        full_name = ""
        address = ""
        dob = ""
        bio = ""
        imageURL = nil
        idImageURL = nil
        reg_no = ""
        allCategories = []
        allTypes = []
        mainCategoryId = nil
        country = ""
        city = ""
        work = ""
        subcategory = ""
        errorMessage = nil
        isLoading = false
    }
}

// MARK: - Helpers

extension Encodable {
    func asDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

struct EmptyBody: Encodable {}

struct VerifyRequest: Encodable {
    let id: String
    let verify_code: String
    let phone_number: String
}

extension RegistrationViewModel {
    func getCompletePhoneNumber() -> String {
        let cleanedMobile = phone_number.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: "")
        let cleanedCode = countryCode.replacingOccurrences(of: "+", with: "")
        if cleanedMobile.hasPrefix(cleanedCode) {
            return cleanedMobile // الرقم مكتمل أصلاً
        } else {
            return "\(cleanedCode)\(cleanedMobile)"
        }
    }
}

extension Notification.Name {
    static let didLoginSuccessfully = Notification.Name("didLoginSuccessfully")
}
