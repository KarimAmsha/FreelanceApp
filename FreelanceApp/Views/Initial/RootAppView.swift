import SwiftUI

struct RootAppView: View {
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var loginStatus: LoginStatus = .welcome

    @ViewBuilder
    var body: some View {
        ZStack {
            contentView
            
//            if appRouter.isLoading {
//                Color.black.opacity(0.2)
//                    .ignoresSafeArea()
//                LoadingView()
//            }
        }
        .overlay {
            if appRouter.isLoading {
                GlobalLoadingView()
            }
        }
        .appBanner(using: appRouter)
        .appAlert(using: appRouter)
    }

    @ViewBuilder
    private var contentView: some View {
        switch settings.userStatus {
        case .registered:
            MainView()
                .environmentObject(userViewModel)
        case .incompleteProfile:
            RegistrationFlowView()
        case .guest, .none:
            WelcomeView(loginStatus: $loginStatus)
        }
    }
}
