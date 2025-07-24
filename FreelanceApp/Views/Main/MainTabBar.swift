//
//  MainTabBar.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 18.07.2025.
//

import SwiftUI

struct MainTabBar: View {
    let tabItems: [MainTabItem]
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            CustomDivider().padding(.bottom)
            HStack(spacing: 0) {
                ForEach(tabItems) { item in
                    TabBarIcon(
                        assignedPage: item.page,
                        width: 28,
                        height: 28,
                        iconName: item.iconSystemName,
                        tabName: item.title,
                        count: item.isNotified ? 5 : nil, // بدّل بعدد الإشعارات الحقيقي عندك!
                        isNotified: item.isNotified
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
            .frame(height: 56)
            .background(Color.white)
        }
        .frame(height: 70)
        .background(Color.white)
    }
}

#Preview {
    MainTabBar(tabItems: [
        MainTabItem(page: .home, iconSystemName: "house", title: "الرئيسية"),
        MainTabItem(page: .chat, iconSystemName: "message", title: "الرسائل", isNotified: true),
        MainTabItem(page: .projects, iconSystemName: "briefcase", title: "المشاريع"),
        MainTabItem(page: .more, iconSystemName: "line.3.horizontal", title: "المزيد")
    ])
    .environmentObject(AppState())
}
