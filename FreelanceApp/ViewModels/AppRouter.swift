import SwiftUI

// MARK: - App Router
final class AppRouter: ObservableObject {

    // MARK: - Navigation Destinations
    enum Destination: Codable, Hashable {
        case profile
        case editProfile
        case changePassword
        case changePhoneNumber
        case contactUs
        case constant(ConstantItem)
        case addressBook
        case addAddressBook
        case editAddressBook(AddressItem)
        case addressBookDetails(AddressItem)
        case notifications
        case notificationsSettings
        case accountSettings
        case freelancerList(categoryId: String, categoryTitle: String, freelancersCount: Int)
        case freelancerProfile(freelancer: Freelancer)
        case serviceDetails
        case chat(chatId: String, currentUserId: String)
        case selectMainSpecialty
        case deliveryDetails
        case earningsView
    }

    // MARK: - State
    @Published var navPath = NavigationPath()
    @Published var appMessage: AppMessage? = nil
    @Published var alertModel: ReusableAlertModel? = nil  // ✅ الجديد
    @Published var isLoading: Bool = false

    // MARK: - Navigation
    func navigate(to destination: Destination) {
        navPath.append(destination)
    }

    func navigateBack() {
        if !navPath.isEmpty {
            navPath.removeLast()
        }
    }

    func navigateToRoot() {
        navPath.removeLast(navPath.count)
    }

    // MARK: - Unified Message API
    func show(_ type: AppMessageType, message: String, title: String? = nil) {
        appMessage = AppMessage(type: type, title: title, message: message)
    }

    func dismissMessage() {
        appMessage = nil
    }
    
    func showAlert(
        title: String,
        message: String? = nil,
        okTitle: String = "موافق",
        cancelTitle: String = "رجوع",
        type: AlertType = .default,
        onOK: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        alertModel = ReusableAlertModel(
            title: title,
            message: message,
            okTitle: okTitle,
            cancelTitle: cancelTitle,
            type: type,
            onOK: onOK,
            onCancel: onCancel
        )
    }

    func dismissAlert() {
        alertModel = nil
    }
}

extension AppRouter {
    func observeState(_ state: LoadingState) {
        switch state {
        case .loading:
            self.isLoading = true
        case .idle, .success, .failure:
            self.isLoading = false
        }

        if case .failure(let err) = state {
            self.show(.error, message: err)
        } else if case .success(let msg) = state, let msg = msg {
            self.show(.success, message: msg)
        }
    }
}

extension View {
    func bindLoadingState(_ state: LoadingState, to router: AppRouter) -> some View {
        self.onChange(of: state) { newState in
            router.observeState(newState)
        }
    }
}

