import Foundation

protocol BaseFilter {
    var categoryId: String { get set }
    var userLatitude: Double { get set }
    var userLongitude: Double { get set }
    var distanceFrom: Int { get set }
    var distanceTo: Int { get set }
    var rateFrom: Int { get set }
    var rateTo: Int { get set }
    var profitFrom: Int { get set }
    var profitTo: Int { get set }
    var name: String { get set }

    mutating func reset()
    func asParameters() -> [String: Any]
}

struct FreelancerFilter: BaseFilter {
    var categoryId: String = ""
    var userLatitude: Double = 0
    var userLongitude: Double = 0
    var distanceFrom: Int = 0
    var distanceTo: Int = 1000
    var rateFrom: Int = 0
    var rateTo: Int = 5
    var profitFrom: Int = 0
    var profitTo: Int = 10
    var name: String = ""

    mutating func reset() {
        categoryId = ""
        userLatitude = 0
        userLongitude = 0
        distanceFrom = 0
        distanceTo = 1000
        rateFrom = 0
        rateTo = 5
        profitFrom = 0
        profitTo = 10
        name = ""
    }

    func asParameters() -> [String: Any] {
        return [
            "category": categoryId,
            "lat": userLatitude,
            "long": userLongitude,
            "distance_from": distanceFrom,
            "distance_to": distanceTo,
            "rate_from": rateFrom,
            "rate_to": rateTo,
            "profit_from": profitFrom,
            "profit_to": profitTo,
            "name": name
        ]
    }
}

extension FreelancerFilter {
    var isDefault: Bool {
        return distanceFrom == 0 &&
               distanceTo == 1000 &&
               rateFrom == 0 &&
               rateTo == 5 &&
               profitFrom == 0 &&
               profitTo == 10
    }
}

