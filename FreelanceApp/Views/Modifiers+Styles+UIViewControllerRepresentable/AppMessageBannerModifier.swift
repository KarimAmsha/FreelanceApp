//
//  AppMessageBannerModifier.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 23.07.2025.
//

import SwiftUI

struct AppMessageBannerModifier: ViewModifier {
    @ObservedObject var router: AppRouter

    func body(content: Content) -> some View {
        ZStack {
            content

            if let msg = router.appMessage {
                AppMessageBannerView(
                    title: msg.title ?? "",
                    message: msg.message,
                    type: msg.type
                ) {
                    router.dismissMessage()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1000)
            }
        }
        .animation(.spring(), value: router.appMessage?.id)
    }
}

extension View {
    func appBanner(using router: AppRouter) -> some View {
        self.modifier(AppMessageBannerModifier(router: router))
    }
}
