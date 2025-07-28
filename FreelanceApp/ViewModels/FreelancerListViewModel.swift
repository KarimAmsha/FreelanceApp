import SwiftUI
import Combine
import Foundation

// MARK: - FreelancerSearchRequest
struct FreelancerSearchRequest: Encodable {
    let category: String
    let long: Double
    let lat: Double
    let distance_from: Int
    let distance_to: Int
    let rate_from: Int
    let rate_to: Int
    let profit_from: Int
    let profit_to: Int
    let name: String?
}

// MARK: - ViewModel
@MainActor
class FreelancerListViewModel: ObservableObject, GenericAPILoadable, Paginatable {
    var appRouter: AppRouter?

    @Published var freelancers: [Freelancer] = []
    @Published var filters = FreelancerFilter()
    @Published var searchText: String = ""
    @Published var pagination: Pagination?
    @Published var currentPage: Int = 0
    @Published var totalPages: Int = 1
    @Published var state: LoadingState = .idle
    @Published var isFetchingMoreData = false

    var userLatitude: Double = 0
    var userLongitude: Double = 0
    var token: String? { UserSettings.shared.token }

    var shouldLoadMoreData: Bool {
        guard let totalPages = pagination?.totalPages else { return false }
        return currentPage < totalPages
    }

    init(categoryId: String) {
        filters.categoryId = categoryId
    }

    func refresh() {
        resetPagination()
        fetchFreelancers(page: 0)
    }

    func loadMoreIfNeeded(currentItem: Freelancer) {
        guard let last = freelancers.last, last.id == currentItem.id else { return }
        guard !isFetchingMoreData && shouldLoadMoreData else { return }
        fetchFreelancers(page: currentPage + 1)
    }

    func fetchFreelancers(page: Int) {
        guard userLatitude != 0, userLongitude != 0 else { return }
        guard tokenGuard(token) else { return }

        startLoading()
        isFetchingMoreData = true

        let isInitialLoad = currentPage == 0 && searchText.isEmpty && filters.isDefault

        let body: FreelancerSearchRequest = {
            if isInitialLoad {
                return FreelancerSearchRequest(
                    category: filters.categoryId,
                    long: userLongitude,
                    lat: userLatitude,
                    distance_from: 0,
                    distance_to: 0,
                    rate_from: 0,
                    rate_to: 0,
                    profit_from: 0,
                    profit_to: 0,
                    name: nil
                )
            } else {
                return FreelancerSearchRequest(
                    category: filters.categoryId,
                    long: userLongitude,
                    lat: userLatitude,
                    distance_from: filters.distanceFrom,
                    distance_to: filters.distanceTo,
                    rate_from: filters.rateFrom,
                    rate_to: filters.rateTo,
                    profit_from: filters.profitFrom,
                    profit_to: filters.profitTo,
                    name: searchText.isEmpty ? nil : searchText
                )
            }
        }()

        let endpoint = APIEndpoint.searchFreelancers(
            page: page,
            limit: 10,
            body: body,
            token: token!
        )

        fetchAPI(endpoint: endpoint, responseType: ArrayAPIResponse<Freelancer>.self) { [weak self] response in
            guard let self = self else { return }
            self.pagination = response.pagination
            self.currentPage = page
            self.freelancers.append(contentsOf: response.items ?? [])
            self.handleSuccess()
        }
    }

    func loadMoreFreelancers() {
        guard shouldLoadMoreData, !isFetchingMoreData else { return }
        fetchFreelancers(page: currentPage + 1)
    }

    func resetPagination() {
        currentPage = 0
        totalPages = 1
        pagination = nil
        isFetchingMoreData = false
        freelancers = []
    }

    private func tokenGuard(_ token: String?) -> Bool {
        guard let token = token, !token.isEmpty else {
            handleError("Token غير متوفر")
            return false
        }
        return true
    }

    deinit {
        APIClient.shared.cancelRequest()
    }
}
