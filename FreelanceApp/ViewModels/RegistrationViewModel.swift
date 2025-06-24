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
    let address: String
    let bio: String
    let dob: String?         // personal فقط
    let reg_no: String?      // company فقط
    let categories: [String]? // personal فقط
    let image: String?       // Firebase URL
    let id_img: String?      // Firebase URL
}

// MARK: - Main ViewModel

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
    @Published var categories: [String] = []
    @Published var bio: String = ""
    @Published var imageURL: String?    // صورة شخصية (Firebase)
    @Published var idImageURL: String?  // صورة هوية (Firebase)

    // حقل الشركة فقط
    @Published var reg_no: String = ""

    // التصنيفات والتخصصات
    @Published var allCategories: [Category] = []
    @Published var selectedCategoryIds: [String] = [] {
        didSet {
            mainSpecialty = allCategories
                .filter { selectedCategoryIds.contains($0.id ?? "") }
                .map { $0.title ?? "" }
                .joined(separator: "، ")
        }
    }
    @Published var mainSpecialty: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    private let errorHandling: ErrorHandling
    @Published var user: User?

    var register_type: String {
        selectedRole?.rawValue ?? ""
    }

    init(errorHandling: ErrorHandling) {
        self.errorHandling = errorHandling
    }

    // MARK: - Build Request Structs

    func toSignupRequest() -> SignupRequest {
        SignupRequest(
            phone_number: phone_number,
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
            address: address,
            bio: bio,
            dob: selectedRole == .personal ? dob : nil,
            reg_no: selectedRole == .company ? reg_no : nil,
            categories: selectedRole == .personal ? (selectedCategoryIds.isEmpty ? categories : selectedCategoryIds) : nil,
            image: imageURL,
            id_img: idImageURL
        )
    }

    // MARK: - API Methods

    func signup(completion: @escaping (Result<User, Error>) -> Void) {
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
                    self.handleUserData()
                    completion(.success(user))
                } else {
                    completion(.failure(APIClient.APIError.customError(message: apiResponse.message)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateProfile(completion: @escaping (Result<User, Error>) -> Void) {
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
                    completion(.success(user))
                } else {
                    completion(.failure(APIClient.APIError.customError(message: apiResponse.message)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Fetch Categories

    func getMainCategories(q: String?) {
        isLoading = true
        errorMessage = nil
        let endpoint = DataProvider.Endpoint.getCategories(q: q)
        DataProvider.shared.request(endpoint: endpoint, responseType: ArrayAPIResponse<Category>.self)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: break
                case .failure(let error): self.handleAPIError(error)
                }
            }, receiveValue: { [weak self] response in
                if response.status, let items = response.items {
                    self?.allCategories = items
                } else {
                    self?.handleAPIError(.customError(message: response.message))
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
        categories = []
        bio = ""
        imageURL = ""
        idImageURL = ""
        reg_no = ""
        allCategories = []
        selectedCategoryIds = []
        mainSpecialty = ""
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
