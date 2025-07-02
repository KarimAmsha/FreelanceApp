//
//  HomeItems.swift
//  Wishy
//
//  Created by Karim Amsha on 20.05.2024.
//

import SwiftUI

struct HomeItems: Codable {
    let category: [CategoryItem]?
    let slider: [SliderItem]?
}

struct CategoryItem: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let image: String?
    let users: Int?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title, description, image, users
    }
}

struct SliderItem: Codable, Identifiable {
    let id: String
    let image: String
    let title: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case image, title, description
    }
}
