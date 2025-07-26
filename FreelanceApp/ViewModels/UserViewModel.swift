import SwiftUI
import Combine
import Foundation

@MainActor
final class UserViewModel: ObservableObject, GenericAPILoadable {
    // MARK: - Published
    @Published var user: User?
    @Published var addressBook: [AddressItem]?
    @Published var state: LoadingState = .idle
    @Published var uploadProgress: Double?

    // MARK: - Props
    var appRouter: AppRouter? = nil
    private let settings = UserSettings.shared
    private var cancellables = Set<AnyCancellable>()
    private var token: String? { settings.token }

    // MARK: - Helpers
    private func tokenGuard() -> Bool {
        guard let token = token, !token.isEmpty else {
            failLoading(error: "Token غير متوفر")
            return false
        }
        return true
    }

    private func handleUserData(_ user: User?) {
        guard let user = user else { return }
        settings.login(user: user, id: user.id ?? "", token: user.token ?? "")
    }

    func updateUploadProgress(_ value: Double) {
        uploadProgress = value
    }

    // MARK: - Fetch User
    func fetchUser(onSuccess: @escaping () -> Void = {}) {
        guard tokenGuard() else { return }

        fetchAPI(endpoint: .getUserProfile(token: token!), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            self?.user = response.items
            self?.handleUserData(response.items)
            self?.finishLoading()
            onSuccess()
        }
    }

    // MARK: - Update User
    func updateUserData(body: UpdateUserRequest, onSuccess: @escaping (String) -> Void) {
        guard tokenGuard() else { return }

        fetchAPI(endpoint: .updateUserData(body: body, token: token!), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            self?.user = response.items
            self?.handleUserData(response.items)
            self?.finishLoading()
            onSuccess(response.message)
        }
    }

    // MARK: - Addresses
    func fetchAddresses() {
        guard tokenGuard() else { return }

        fetchAPI(endpoint: .getAddressList(token: token!), responseType: ArrayAPIResponse<AddressItem>.self) { [weak self] response in
            self?.addressBook = response.items
            self?.finishLoading()
        }
    }

    func addAddress(body: AddressRequest, onSuccess: @escaping (String) -> Void) {
        guard tokenGuard() else { return }

        fetchAPI(endpoint: .addAddress(body: body, token: token!), responseType: SingleAPIResponse<AddressItem>.self) {
            self.finishLoading()
            onSuccess($0.message)
        }
    }

    func updateAddress(body: AddressRequest, onSuccess: @escaping (String) -> Void) {
        guard tokenGuard() else { return }

        fetchAPI(endpoint: .updateAddress(body: body, token: token!), responseType: SingleAPIResponse<AddressItem>.self) {
            self.finishLoading()
            onSuccess($0.message)
        }
    }

    func deleteAddress(id: String, onSuccess: @escaping (String) -> Void) {
        guard tokenGuard() else { return }

        fetchAPI(endpoint: .deleteAddress(id: id, token: token!), responseType: ArrayAPIResponse<AddressItem>.self) {
            self.finishLoading()
            onSuccess($0.message)
        }
    }

    func fetchAddressByType(type: String) {
        guard tokenGuard() else { return }

        fetchAPI(endpoint: .getAddressByType(type: type, token: token!), responseType: ArrayAPIResponse<AddressItem>.self) { [weak self] response in
            self?.addressBook = response.items
            self?.finishLoading()
        }
    }

    // MARK: - Complaint
    func addComplaint(body: ComplainRequest, onSuccess: @escaping (String) -> Void) {
        guard tokenGuard() else { return }

        fetchAPI(endpoint: .addComplain(body: body, token: token!), responseType: SingleAPIResponse<Complain>.self) {
            self.finishLoading()
            onSuccess($0.message)
        }
    }

    // MARK: - FCM Token
    func refreshFcmToken(body: RefreshFcmRequest, onSuccess: @escaping () -> Void) {
        guard tokenGuard() else { return }

        fetchAPI(endpoint: .refreshFcmToken(body: body, token: token!), responseType: SingleAPIResponse<User>.self) { [weak self] response in
            self?.user = response.items
            self?.finishLoading()
            onSuccess()
        }
    }

    // MARK: - Update Specialty
    // MARK: - Update Specialty (Main or Sub)
    func updateUserSpecialty(to categoryId: String? = nil, subCategoryId: String? = nil, onSuccess: @escaping () -> Void) {
        guard let user = UserSettings.shared.user else {
            failLoading(error: "تعذر جلب بيانات المستخدم")
            return
        }

        let req = UpdateUserRequest(
            email: user.email ?? "",
            full_name: user.full_name ?? "",
            lat: user.lat ?? 0,
            lng: user.lng ?? 0,
            reg_no: user.reg_no,
            address: user.address,
            country: user.country,
            city: user.city,
            dob: user.dob,
            category: categoryId ?? user.mainSpecialtyId,
            subcategory: subCategoryId ?? user.subcategory,
            work: user.work,
            bio: user.bio,
            image: user.image,
            id_image: user.id_image
        )

        updateUserData(body: req) { _ in
            self.fetchUser {
                onSuccess()
            }
        }
    }
}

struct UpdateUserRequest: Encodable {
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
    let id_image: String?
}

struct AddressRequest: Encodable {
    let title: String
    let lat: Double
    let lng: Double
    let description: String?
    let type: String?      // مثل: "personal", "friend"
    let contact_name: String?
    let contact_phone: String?
    let floor: String?
    let apartment: String?
    let building: String?
    let area: String?
    let city: String?
}

struct ComplainRequest: Encodable {
    let subject: String
    let message: String
    let user_id: String?    // في حال مطلوب
    let order_id: String?   // في حال الشكوى مرتبطة بطلب
}

struct RefreshFcmRequest: Encodable {
    let id: String
    let fcmToken: String
}

