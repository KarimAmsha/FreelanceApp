import SwiftUI
import Combine
import Foundation

enum UserStatus: String, Codable {
    case guest
    case incompleteProfile
    case registered
    case none
}

class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @Published var user: User?
    @Published var id: String?
    @Published var token: String?
    @AppStorage("userRole") var userRole: UserRole = .personal
    @AppStorage("userStatus") var userStatus: UserStatus = .none
    @AppStorage("loggedIn") var loggedIn: Bool = false

    @Published var fcmToken: String? {
        didSet {
            if let token = fcmToken {
                UserDefaults.standard.set(token, forKey: Keys.fcmToken)
            }
        }
    }

    // MARK: - Init
    init() {
        // حمل بيانات المستخدم إن وجدت
        if let storedUser = loadUserFromStorage() {
            user = storedUser.user
            id = storedUser.id
            token = storedUser.token
        }
        // fcmToken فقط للقراءة، إذا تحتاج
        fcmToken = UserDefaults.standard.string(forKey: Keys.fcmToken)
    }

    // MARK: - Actions

    func login(user: User, id: String, token: String) {
        self.user = user
        self.id = id
        self.token = token
        self.loggedIn = true
        self.userStatus = .registered

        if let role = user.register_type, let userRole = UserRole(rawValue: role) {
            self.userRole = userRole
        }
        saveUserToStorage(user: user, id: id, token: token)
    }

    func setIncompleteProfile(user: User, id: String, token: String) {
        self.user = user
        self.id = id
        self.token = token
        self.loggedIn = false
        self.userStatus = .incompleteProfile

        if let role = user.register_type, let userRole = UserRole(rawValue: role) {
            self.userRole = userRole
        }
        saveUserToStorage(user: user, id: id, token: token)
    }

    func guestLogin(token: String) {
        self.user = nil
        self.id = nil
        self.token = token
        self.loggedIn = true
        self.userStatus = .guest
        saveTokenToStorage(token: token)
    }

    func logout() {
        clearUserData()
        loggedIn = false
        userStatus = .none
        userRole = .none
    }

    // MARK: - Storage

    private func loadUserFromStorage() -> (user: User, id: String, token: String)? {
        if let userData = UserDefaults.standard.data(forKey: Keys.userData),
           let decodedUser = try? JSONDecoder().decode(User.self, from: userData),
           let storedId = UserDefaults.standard.string(forKey: Keys.id),
           let storedToken = UserDefaults.standard.string(forKey: Keys.token) {
            return (user: decodedUser, id: storedId, token: storedToken)
        }
        return nil
    }

    private func saveUserToStorage(user: User, id: String, token: String) {
        if let encodedData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedData, forKey: Keys.userData)
            UserDefaults.standard.set(id, forKey: Keys.id)
            UserDefaults.standard.set(token, forKey: Keys.token)
        }
    }

    private func saveTokenToStorage(token: String) {
        UserDefaults.standard.set(token, forKey: Keys.token)
    }

    private func clearUserData() {
        user = nil
        id = nil
        token = nil

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.userData)
        defaults.removeObject(forKey: Keys.id)
        defaults.removeObject(forKey: Keys.token)
        defaults.removeObject(forKey: "_userRole")     // AppStorage key
        defaults.removeObject(forKey: "_userStatus")   // AppStorage key
        defaults.removeObject(forKey: "_loggedIn")
    }

    private struct Keys {
        static let id = "id"
        static let userData = "userData"
        static let token = "token"
        static let fcmToken = "fcmToken"
    }
}
