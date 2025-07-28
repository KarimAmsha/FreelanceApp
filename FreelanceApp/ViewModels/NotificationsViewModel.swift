import SwiftUI
import Combine
import Alamofire

@MainActor
class NotificationsViewModel: ObservableObject, GenericAPILoadable, Paginatable {

    // MARK: - Published
    @Published var notificationsItems: [NotificationItem] = []
    @Published var state: LoadingState = .idle
    @Published var currentPage: Int = 0
    @Published var totalPages: Int = 1
    @Published var pagination: Pagination?
    @Published var isFetchingMoreData = false

    // MARK: - Props
    var appRouter: AppRouter? = nil
    private var token: String? { UserSettings.shared.token }
    private var userId: String? { UserSettings.shared.id }

    // MARK: - Computed
    var shouldLoadMoreData: Bool { currentPage < totalPages }

    // MARK: - Token Guard
    private func tokenGuard() -> Bool {
        guard let token = token, !token.isEmpty else {
            failLoading(error: "Token غير متوفر")
            return false
        }
        return true
    }

    // MARK: - Reset
    func resetPagination() {
        currentPage = 0
        totalPages = 1
        pagination = nil
        isFetchingMoreData = false
        notificationsItems = []
    }

    // MARK: - Loading Helpers
    func startLoading() {
        state = .loading
    }

    func finishLoading(message: String? = nil) {
        state = .success(message: message)
    }

    func failLoading(error: String) {
        isFetchingMoreData = false
        state = .failure(error: error)
    }

    func shouldStartLoading() -> Bool {
        if state.isLoading { return false }
        return true
    }

    func resetState() {
        state = .idle
    }

    // MARK: - Fetch
    func fetchNotificationsItems(page: Int = 0) {
        guard tokenGuard() else { return }
        if page == 0 { resetPagination() }

        isFetchingMoreData = true
        startLoading()

        fetchAPI(
            endpoint: .getNotifications(page: page, limit: 20, token: token!),
            responseType: ArrayAPIResponse<NotificationItem>.self
        ) { [weak self] response in
            guard let self = self else { return }

            self.notificationsItems += response.items ?? []
            self.pagination = response.pagination
            self.currentPage = response.pagination?.pageNumber ?? page
            self.totalPages = response.pagination?.totalPages ?? 1
            self.isFetchingMoreData = false
            self.finishLoading()
        }
    }

    func loadMoreNotifications() {
        guard !isFetchingMoreData, shouldLoadMoreData else { return }
        fetchNotificationsItems(page: currentPage + 1)
    }

    func refreshNotifications() {
        fetchNotificationsItems(page: 0)
    }

    // MARK: - Delete
    func deleteNotification(id: String, onSuccess: @escaping (String) -> Void) {
        guard tokenGuard() else { return }

        fetchAPI(
            endpoint: .deleteNotification(id: id, token: token!),
            responseType: APIResponseCodable.self
        ) {
            self.finishLoading()
            onSuccess($0.message)
        }
    }

    // MARK: - Send FCM Notification
    func sendNotification(saveNotifi: Bool = false, idsArray: [String], obj: NotificationsStruct) {
        guard obj.receiverId != userId else { return }

        let parameters: Parameters = [
            "registration_ids": idsArray,
            "priority": "high",
            "notification": [
                "body": obj.message,
                "sound": 1,
                "title": obj.title,
                "type": obj.type?.value ?? "",
                "uid": obj.receiverId,
                "object": obj.toDict(),
                "badge": "1"
            ]
        ]

        sendRequestPost(param: parameters) { response in
            switch response.result {
            case .success(let data):
                print("✅ Notification sent: \(data)")
            case .failure(let error):
                print("❌ Notification Send Error: \(error.localizedDescription)")
            }
        }
    }

    private func sendRequestPost(
        param: Parameters,
        completion: @escaping (AFDataResponse<Data>) -> Void
    ) {
        let headers = Constants.headers
        AF.request(
            Constants.FCMLink,
            method: .post,
            parameters: param,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .responseData { response in
            completion(response)
        }
    }
}
