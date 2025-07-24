//
//  WelcomeView.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI
import PopupView

struct WelcomeView: View {
    @State private var currentPage = 0
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var viewModel = InitialViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @EnvironmentObject var regViewModel: RegistrationViewModel
    @Binding var loginStatus: LoginStatus

    var body: some View {
        NavigationStack(path: $appRouter.navPath) {
            ZStack {
                switch loginStatus {
                case .welcome:
                    welcomeScreen
                case .login:
                    LoginView(
                        loginStatus: $loginStatus
                    )
                    .environmentObject(regViewModel)
                case .verification:
                    SMSVerificationView(
                        loginStatus: $loginStatus
                    )
                    .environmentObject(regViewModel)
                case .completeProfile:
                    RegistrationFlowView()
                        .environmentObject(regViewModel)
                case .home:
                    MainView()
                }
            }
        }
        .onAppear {
            viewModel.fetchWelcomeItems()
        }
        .onChange(of: loginStatus) { newValue in
            print("🚀 loginStatus changed to:", newValue)
        }
    }

    private var welcomeScreen: some View {
        VStack(spacing: 20) {
            VStack(spacing: 0) {
                if viewModel.state.isLoading {
                    LoadingView()
                } else if let items = viewModel.welcomeItems, !items.isEmpty {
                    TabView(selection: $currentPage) {
                        ForEach(0..<min(items.count, 3), id: \.self) { index in
                            WelcomeSlideView(item: items[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                    ControlDots(numberOfPages: 3, currentPage: $currentPage)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Button {
                        withAnimation {
                            if currentPage < 2 {
                                currentPage += 1
                            } else {
                                loginStatus = .login
                            }
                        }
                    } label: {
                        Text(currentPage < 2 ? "التالي" : "سجّل الآن")
                    }
                    .buttonStyle(
                        GradientPrimaryButton(
                            fontSize: 16,
                            fontWeight: .bold,
                            background: Color.primaryGradientColor(),
                            foreground: .white,
                            height: 48,
                            radius: 12
                        )
                    )
                }

                Button {
                    authViewModel.guest {
                        settings.loggedIn = true
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("الدخول كزائر")
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .buttonStyle(
                    PrimaryButton(
                        fontSize: 14,
                        fontWeight: .regular,
                        background: .backgroundFEFEFE(),
                        foreground: .black151515(),
                        height: 48,
                        radius: 12
                    )
                )
            }
        }
        .padding()
        .background(Color.background())
    }
}

#Preview {
    WelcomeView(loginStatus: .constant(.welcome))
        .environmentObject(LanguageManager())
        .environmentObject(UserSettings())
        .environmentObject(AppRouter())
}
