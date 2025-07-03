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

    // فلترة
    @Published var distanceFrom: Int = 0
    @Published var distanceTo: Int = 1000
    @Published var rateFrom: Int = 0
    @Published var rateTo: Int = 5
    @Published var profitFrom: Int = 0
    @Published var profitTo: Int = 10

    // الموقع، يتم جلبها من LocationManager
    @Published var userLongitude: Double = 0
    @Published var userLatitude: Double = 0

    private var cancellables = Set<AnyCancellable>()
    private let errorHandling: ErrorHandling
    var categoryId: String

    init(categoryId: String, errorHandling: ErrorHandling = ErrorHandling()) {
        self.categoryId = categoryId
        self.errorHandling = errorHandling
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

        // إعداد الباراميترز ديناميكياً
        var params: [String: Any] = [
            "category": categoryId,
            "page": page,
            "limit": 20
        ]

        // أضف الموقع إذا متوفر (غير صفر)
        if userLongitude != 0 && userLatitude != 0 {
            params["long"] = userLongitude
            params["lat"] = userLatitude
        }

        // أضف الفلاتر فقط لو تغيرت عن الافتراضي (اختياري)
        if distanceFrom > 0 { params["distance_from"] = distanceFrom }
        if distanceTo < 1000 { params["distance_to"] = distanceTo }
        if rateFrom > 0 { params["rate_from"] = rateFrom }
        if rateTo < 5 { params["rate_to"] = rateTo }
        if profitFrom > 0 { params["profit_from"] = profitFrom }
        if profitTo < 10 { params["profit_to"] = profitTo }
        if !searchText.isEmpty { params["name"] = searchText }

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
            print("eeeee \(response)")
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
