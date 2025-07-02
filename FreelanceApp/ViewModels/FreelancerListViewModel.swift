import SwiftUI
import Combine
import Alamofire

class FreelancerListViewModel: ObservableObject {
    @Published var freelancers: [Freelancer] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var pagination: Pagination?
    @Published var currentPage: Int = 0
    @Published var totalPages: Int = 1
    @Published var isFetchingMoreData = false
    @Published var userSettings = UserSettings.shared

    private var cancellables = Set<AnyCancellable>()
    private let errorHandling: ErrorHandling
    var categoryId: String

    init(categoryId: String, errorHandling: ErrorHandling = ErrorHandling()) {
        self.categoryId = categoryId
        self.errorHandling = errorHandling
        fetchFreelancers(page: 0)
    }

    func fetchFreelancers(page: Int = 0) {
        guard let token = userSettings.token else {
            self.handleAPIError(.customError(message: LocalizedStringKey.tokenError))
            return
        }

        if page == 0 {
            self.freelancers = []
        }
        isLoading = page == 0
        isFetchingMoreData = page != 0
        errorMessage = nil

        var params: [String: Any] = [
            "category": categoryId,
            "page": page,
            "limit": 20 // عدل حسب الحاجة
        ]
        if !searchText.isEmpty {
            params["name"] = searchText
        }

        let endpoint = APIEndpoint.searchFreelancers(params: params, token: token)

        AF.request(
            endpoint.fullURL,
            method: endpoint.method,
            parameters: endpoint.parameters,
            encoding: URLEncoding.default,
            headers: endpoint.headers
        )
        .validate()
        .responseDecodable(of: FreelancerListResponse.self) { [weak self] response in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.isFetchingMoreData = false
                switch response.result {
                case .success(let res):
                    if res.status, let items = res.items {
                        if page == 0 {
                            self?.freelancers = items
                        } else {
                            self?.freelancers += items
                        }
                        self?.pagination = res.pagination
                        self?.currentPage = res.pagination?.pageNumber ?? 0
                        self?.totalPages = res.pagination?.totalPages ?? 1
                    } else {
                        self?.errorMessage = res.message ?? "حدث خطأ"
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func loadMoreIfNeeded(currentItem item: Freelancer?) {
        guard let item = item else { return }
        let thresholdIndex = freelancers.index(freelancers.endIndex, offsetBy: -5)
        if freelancers.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadMoreFreelancers()
        }
    }

    func loadMoreFreelancers() {
        guard !isFetchingMoreData, currentPage + 1 < totalPages else { return }
        fetchFreelancers(page: currentPage + 1)
    }

    func refresh() {
        currentPage = 0
        fetchFreelancers(page: 0)
    }
}

extension FreelancerListViewModel {
    private func handleAPIError(_ error: APIClient.APIError) {
        let errorDescription = errorHandling.handleAPIError(error)
        errorMessage = errorDescription
    }
}
