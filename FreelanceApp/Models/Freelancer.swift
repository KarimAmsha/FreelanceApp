import SwiftUI

struct FreelancerListResponse: Codable {
    let status: Bool
    let code: Int?
    let message: String?
    let items: [Freelancer]?
    let pagination: Pagination?
}

import Foundation

struct Freelancer: Identifiable, Codable, Hashable {
    let id: String?
    let full_name: String?
    let title: String?
    let bio: String?
    let image: String?
    let rating: Double?
    let completedProjects: Int?
    let completedServices: Int?
    let price: Double?
    let joinedAt: String?
    let portfolio: [PortfolioItem]?
    let services: [Service]?
    let reviews: [Review]?
    let clientsCount: Int?
    
    init(
        id: String? = nil,
        full_name: String? = nil,
        title: String? = nil,
        bio: String? = nil,
        image: String? = nil,
        rating: Double? = nil,
        completedProjects: Int? = nil,
        completedServices: Int? = nil,
        price: Double? = nil,
        joinedAt: String? = nil,
        portfolio: [PortfolioItem]? = nil,
        services: [Service]? = nil,
        reviews: [Review]? = nil,
        clientsCount: Int? = nil
    ) {
        self.id = id
        self.full_name = full_name
        self.title = title
        self.bio = bio
        self.image = image
        self.rating = rating
        self.completedProjects = completedProjects
        self.completedServices = completedServices
        self.price = price
        self.joinedAt = joinedAt
        self.portfolio = portfolio
        self.services = services
        self.reviews = reviews
        self.clientsCount = clientsCount
    }

    var joinedAtFormatted: String? {
        guard let joinedAt = joinedAt else { return nil }
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: joinedAt) else { return nil }
        let outFormatter = DateFormatter()
        outFormatter.locale = Locale(identifier: "ar")
        outFormatter.dateStyle = .long
        return outFormatter.string(from: date)
    }
    
    // ديكودر مخصص للتعامل مع القيم الغلط من السيرفر
    enum CodingKeys: String, CodingKey {
        case id, full_name, title, bio, image, rating, completedProjects, completedServices, price, joinedAt, portfolio, services, reviews, clientsCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decodeIfPresent(String.self, forKey: .id)
        full_name = try? container.decodeIfPresent(String.self, forKey: .full_name)
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        bio = try? container.decodeIfPresent(String.self, forKey: .bio)
        image = try? container.decodeIfPresent(String.self, forKey: .image)
        rating = try? container.decodeIfPresent(Double.self, forKey: .rating)
        completedProjects = try? container.decodeIfPresent(Int.self, forKey: .completedProjects)
        completedServices = try? container.decodeIfPresent(Int.self, forKey: .completedServices)
        price = try? container.decodeIfPresent(Double.self, forKey: .price)
        joinedAt = try? container.decodeIfPresent(String.self, forKey: .joinedAt)
        portfolio = try? container.decodeIfPresent([PortfolioItem].self, forKey: .portfolio)
        reviews = try? container.decodeIfPresent([Review].self, forKey: .reviews)
        clientsCount = try? container.decodeIfPresent(Int.self, forKey: .clientsCount)
        
        // ديكودر مرن للـ services
        if let arr = try? container.decodeIfPresent([Service].self, forKey: .services) {
            services = arr
        } else {
            // لو رجعها السيرفر رقم أو null أو حتى نص فاضي
            services = []
        }
    }
    
    // لو أردت ترميز عكسي (عادة لن تحتاجه هنا)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(full_name, forKey: .full_name)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(completedProjects, forKey: .completedProjects)
        try container.encodeIfPresent(completedServices, forKey: .completedServices)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(joinedAt, forKey: .joinedAt)
        try container.encodeIfPresent(portfolio, forKey: .portfolio)
        try container.encodeIfPresent(services, forKey: .services)
        try container.encodeIfPresent(reviews, forKey: .reviews)
        try container.encodeIfPresent(clientsCount, forKey: .clientsCount)
    }
}

struct PortfolioItem: Identifiable, Codable, Hashable {
    let id: String?
    let title: String?
    let description: String?
    let image: String?
}

struct Service: Identifiable, Codable, Hashable {
    let id: String?
    let title: String?
    let image: String?
    let price: Double?
    let rating: Double?
}

struct Review: Identifiable, Codable, Hashable {
    let id: String?
    let userName: String?
    let userTitle: String?
    let userImage: String?
    let rating: Double?
    let text: String?
}
