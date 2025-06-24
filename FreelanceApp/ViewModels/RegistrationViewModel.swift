//
//  RegistrationViewModel.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 24.06.2025.
//

import SwiftUI
import Combine

class RegistrationViewModel: ObservableObject {
    @Published var selectedRole: UserRole? = nil

    // باقي الحقول
    @Published var phone_number: String = ""
    @Published var os: String = "IOS"
    @Published var fcmToken: String = ""
    @Published var lat: Double = 0.0
    @Published var lng: Double = 0.0
    @Published var app_type: String = "customer"

    // -- حقول الحساب الشخصي --
    @Published var email: String = ""
    @Published var full_name: String = ""
    @Published var address: String = ""
    @Published var dob: String = ""              // personal فقط
    @Published var categories: [String] = []     // personal فقط
    @Published var bio: String = ""
    @Published var imageURL: String? // صورة شخصية
    @Published var idImageURL: String? // صورة هوية

    // -- حقل الشركة فقط --
    @Published var reg_no: String = ""           // company فقط

    // مساعدة:
    var register_type: String {
        selectedRole?.rawValue ?? ""
    }
    
    @Published var allCategories: [Category] = []
    @Published var selectedCategoryIds: [String] = [] {
        didSet {
            mainSpecialty = allCategories
                .filter { selectedCategoryIds.contains($0.id ?? "") }
                .map { $0.title ?? "" }
                .joined(separator: "، ")
        }
    }
    @Published var mainSpecialty: String = "" // لإظهار الاسم في الواجهة فقط
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    private let errorHandling: ErrorHandling

    init(errorHandling: ErrorHandling) {
        self.errorHandling = errorHandling
    }

    func buildSignupRequest() -> [String: Any] {
        [
            "phone_number": phone_number,
            "os": os,
            "fcmToken": fcmToken,
            "lat": lat,
            "lng": lng,
            "register_type": selectedRole?.rawValue ?? "",
            "app_type": app_type
        ]
    }

    func buildProfileRequest() -> [String: Any] {
        var dict: [String: Any] = [
            "email": email,
            "full_name": full_name,
            "lat": lat,
            "lng": lng,
            "address": address,
            "bio": bio
        ]
        if selectedRole == .company {
            dict["reg_no"] = reg_no
        } else if selectedRole == .personal {
            dict["dob"] = dob
            // اربط categories بالاختيارات الحالية دائمًا
            let categoryList = selectedCategoryIds.isEmpty ? categories : selectedCategoryIds
            for (idx, cat) in categoryList.enumerated() {
                dict["categories[\(idx)]"] = cat
            }
        }
        if let imgUrl = imageURL {
            dict["image"] = imgUrl
        }
        if let idImgUrl = idImageURL {
            dict["id_img"] = idImgUrl
        }
        return dict
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

    func getMainCategories(q: String?) {
        isLoading = true
        errorMessage = nil
        let endpoint = DataProvider.Endpoint.getCategories(q: q)
        
        DataProvider.shared.request(endpoint: endpoint, responseType: ArrayAPIResponse<Category>.self)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    // Use the centralized error handling component
                    self.handleAPIError(error)
                }
            }, receiveValue: { [weak self] (response: ArrayAPIResponse<Category>) in
                if response.status {
                    if let items = response.items {
                        self?.allCategories = items
                        self?.errorMessage = nil
                    }
                } else {
                    // Use the centralized error handling component
                    self?.handleAPIError(.customError(message: response.message))
                }
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }
}

extension RegistrationViewModel {
    private func handleAPIError(_ error: APIClient.APIError) {
        let errorDescription = errorHandling.handleAPIError(error)
        errorMessage = errorDescription
    }
}
