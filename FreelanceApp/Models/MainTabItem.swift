//
//  MainTabItem.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 7.05.2025.
//


import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case home, chat, projects, addService, more
    var id: String { rawValue }
}

struct MainTabItem: Identifiable {
    let page: MainTab
    let iconSystemName: String
    let title: String
    var isNotified: Bool = false
    var id: MainTab { page }
}
