import SwiftUI
import Combine
import Alamofire

@MainActor
class InitialViewModel: ObservableObject, GenericAPILoadable, Paginatable {
    var appRouter: AppRouter?

    // MARK: - Published
    @Published var welcomeItems: [WelcomeItem]?
    @Published var constantsItems: [ConstantItem]?
    @Published var mainCategoryItems: [MainCategory]?
    @Published var constantItem: ConstantItem?
    @Published var appconstantsItems: AppConstants?
    @Published var homeItems: HomeItems?
    @Published var products: [Products] = []
    @Published var product: Products?
    @Published var appContactItem: [Contact] = []
    @Published var whatsAppContactItem: Contact?
    @Published var favoriteItem: FavoriteItem?
    @Published var favoriteItems: [FavoriteItems] = []

    // MARK: - Pagination
    @Published var pagination: Pagination?
    @Published var currentPage: Int = 0
    @Published var totalPages: Int = 1
    @Published var isFetchingMoreData: Bool = false

    // MARK: - Loading State
    @Published var state: LoadingState = .idle
    var isLoading: Bool { state.isLoading }
    var isSuccess: Bool { state.isSuccess }
    var isFailure: Bool { state.isFailure }
    var errorMessage: String? { state.message }
    var shouldLoadMoreData: Bool { currentPage < totalPages }

    // MARK: - Private
    private var token: String? { UserSettings.shared.token }

    private func tokenGuard() -> Bool {
        guard token != nil else {
            failLoading(error: "Token غير متوفر")
            return false
        }
        return true
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

    // MARK: - GenericAPILoadable
    func handleSuccess(message: String? = nil) {
        isFetchingMoreData = false
        finishLoading(message: message)
    }

    func handleError(_ error: String) {
        failLoading(error: error)
    }

    // MARK: - Reset Pagination
    func resetPagination() {
        currentPage = 0
        totalPages = 1
        pagination = nil
        isFetchingMoreData = false
        products = []
    }

    // MARK: - Requests

    func fetchWelcomeItems() {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .getWelcome, responseType: ArrayAPIResponse<WelcomeItem>.self) {
            self.welcomeItems = $0.items
            self.finishLoading()
        }
    }

    func fetchConstantsItems() {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .getConstants, responseType: ArrayAPIResponse<ConstantItem>.self) {
            self.constantsItems = $0.items
            self.finishLoading()
        }
    }

    func fetchConstantItemDetails(_id: String) {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .getConstantDetails(_id: _id), responseType: SingleAPIResponse<ConstantItem>.self) {
            self.constantItem = $0.items
            self.finishLoading()
        }
    }

    func fetchAppConstantsItems() {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .getAppConstants, responseType: SingleAPIResponse<AppConstants>.self) {
            self.appconstantsItems = $0.items
            self.finishLoading()
        }
    }

    func fetchHomeItems() {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .getHome, responseType: SingleAPIResponse<HomeItems>.self) {
            self.homeItems = $0.items
            self.finishLoading()
        }
    }

    func fetchContactItems() {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .getContact, responseType: ArrayAPIResponse<Contact>.self) {
            self.appContactItem = $0.items ?? []
            self.whatsAppContactItem = $0.items?.first(where: { $0.id == "665c8b4f952065449ef7248f" })
            self.finishLoading()
        }
    }

    func getMainCategories() {
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .getCategories, responseType: ArrayAPIResponse<MainCategory>.self) {
            self.mainCategoryItems = $0.items
            self.finishLoading()
        }
    }

    // MARK: - Products

    func getProducts(body: ProductListRequest) {
        guard tokenGuard() else { return }
        guard shouldStartLoading() else { return }
        startLoading()
        isFetchingMoreData = true

        fetchAPI(
            endpoint: .getProducts(
                page: body.page,
                limit: body.limit ?? 20,
                body: body,
                token: token!
            ),
            responseType: ArrayAPIResponse<Products>.self
        ) { [weak self] response in
            guard let self = self else { return }

            if body.page == 1 || self.products.isEmpty {
                self.products = response.items ?? []
            } else {
                self.products += response.items ?? []
            }

            self.pagination = response.pagination
            self.totalPages = response.pagination?.totalPages ?? 1
            self.currentPage = response.pagination?.pageNumber ?? body.page
            self.handleSuccess()
        }
    }

    func loadMoreProducts(currentBody: ProductListRequest) {
        guard shouldLoadMoreData, !isFetchingMoreData else { return }
        var newBody = currentBody
        newBody.page += 1
        getProducts(body: newBody)
    }

    func refreshProducts(initialBody: ProductListRequest) {
        resetPagination()
        var refreshedBody = initialBody
        refreshedBody.page = 1
        getProducts(body: refreshedBody)
    }

    func getProductDetails(id: String) {
        guard tokenGuard() else { return }
        guard shouldStartLoading() else { return }
        startLoading()

        fetchAPI(endpoint: .getProductDetails(id: id, token: token!), responseType: BaseCustomStatusAPIResponse<Products>.self) { [weak self] response in
            self?.product = response.items
            self?.finishLoading()
        }
    }

    // MARK: - Actions
    func handleButtonTapped(index: Int) {
        guard let url = URL(string: appContactItem[safe: index]?.Data ?? "") else {
            failLoading(error: "رابط غير صالح")
            return
        }
        UIApplication.shared.open(url)
    }
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - ProductListRequest Model
struct ProductListRequest: Encodable {
    var page: Int
    var limit: Int?
    var category_id: String?
    var keyword: String?
    var lat: Double?
    var lng: Double?
    var sort: String? // مثل: "latest", "popular"
}
