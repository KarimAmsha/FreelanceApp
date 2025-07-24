//
//  GenericPagination.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 18.07.2025.
//

import Foundation

// MARK: - Pagination Struct (Decodable from API)

struct Pagination: Codable {
    let pageNumber: Int
    let totalPages: Int
    let totalItems: Int
    let itemsPerPage: Int

    enum CodingKeys: String, CodingKey {
        case pageNumber
        case totalPages
        case totalItems = "totalElements"
        case itemsPerPage = "size"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.pageNumber = try container.decodeIfPresent(Int.self, forKey: .pageNumber) ?? 0
        self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        self.totalItems = try container.decodeIfPresent(Int.self, forKey: .totalItems) ?? 0
        self.itemsPerPage = try container.decodeIfPresent(Int.self, forKey: .itemsPerPage) ?? 20
    }

    init(pageNumber: Int = 0, totalPages: Int = 1, totalItems: Int = 0, itemsPerPage: Int = 20) {
        self.pageNumber = pageNumber
        self.totalPages = totalPages
        self.totalItems = totalItems
        self.itemsPerPage = itemsPerPage
    }
}

// MARK: - Paginatable Protocol

@MainActor
protocol Paginatable {
    var currentPage: Int { get set }
    var totalPages: Int { get set }
    var pagination: Pagination? { get set }

    var shouldLoadMoreData: Bool { get }
    func resetPagination()
}

extension Paginatable {
    var shouldLoadMoreData: Bool {
        currentPage + 1 < totalPages
    }
}
