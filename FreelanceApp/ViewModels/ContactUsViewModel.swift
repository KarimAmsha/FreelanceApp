import Foundation
import Combine

@MainActor
class ContactUsViewModel: ObservableObject, GenericAPILoadable {
    // MARK: - Published
    @Published var state: LoadingState = .idle
    @Published var appContactItem: [Contact] = []
    @Published var whatsAppContactItem: Contact?

    // MARK: - AppRouter
    var appRouter: AppRouter? = nil

    // MARK: - Helpers
    var isLoading: Bool { state.isLoading }
    var isSuccess: Bool { state.isSuccess }
    var isFailure: Bool { state.isFailure }
    var errorMessage: String? { state.message }

    // MARK: - Token
    private var token: String? {
        UserSettings.shared.token
    }

    private func tokenGuard() -> Bool {
        guard token != nil else {
            failLoading(error: "يرجى تسجيل الدخول أولاً")
            return false
        }
        return true
    }

    // MARK: - Fetch Contacts
    func fetchContactItems() {
        fetchAPI(endpoint: .getContact, responseType: ArrayAPIResponse<Contact>.self) {
            self.appContactItem = $0.items ?? []
            self.whatsAppContactItem = $0.items?.first(where: { $0.id == "665c8b4f952065449ef7248f" })
        }
    }

    // MARK: - Send Complaint
    func addComplain(body: AddComplaintRequest, onSuccess: @escaping (String) -> Void) {
        guard tokenGuard() else { return }

        fetchAPI(endpoint: .addComplain(body: body, token: token!), responseType: MessageResponse.self) { response in
            self.finishLoading(response.message)
            onSuccess(response.message ?? "تم الإرسال بنجاح")
        }
    }
}

// MARK: - Models

struct AddComplaintRequest: Encodable {
    let full_name: String
    let email: String
    let phone_number: String
    let details: String
}

struct MessageResponse: Decodable, APIBaseResponse {
    var status: Bool
    var message: String
}
