//
//  ProfileView.swift
//  Wishy
//
//  Created by Karim Amsha on 30.04.2024.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userSettings: UserSettings
    @StateObject private var initialViewModel = InitialViewModel()
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    ProfileCardView(
                        name: userSettings.user?.full_name ?? "اسم المستخدم",
                        phone: userSettings.user?.phone_number ?? "55 ### ####",
                        imageUrl: userSettings.user?.image
                    )

                    VStack(spacing: 0) {
                        settingsRow(title: "أرباحي", icon: .system(name: "bag")) {
                            appRouter.navigate(to: .earningsView)
                        }
                        settingsRow(title: "الإشعارات", icon: .system(name: "bell")) {
                            appRouter.navigate(to: .notifications)
                        }
                        settingsRow(title: "إعدادات الحساب", icon: .system(name: "gearshape")) {
                            appRouter.navigate(to: .accountSettings)
                        }
                        settingsRow(title: LocalizedStringKey.contactUs, icon: .asset(name: "ic_support")) {
                            appRouter.navigate(to: .contactUs)
                        }
                        settingsRow(title: LocalizedStringKey.aboutApp, icon: .asset(name: "ic_mobile")) {
                            if let item = initialViewModel.constantsItems?.first(where: { $0.constantType == .about }) {
                                appRouter.navigate(to: .constant(item))
                            }
                        }
                        settingsRow(title: LocalizedStringKey.termsConditions, icon: .asset(name: "ic_lock")) {
                            if let item = initialViewModel.constantsItems?.first(where: { $0.constantType == .terms }) {
                                appRouter.navigate(to: .constant(item))
                            }
                        }
                        settingsRow(title: LocalizedStringKey.privacyPolicy, icon: .asset(name: "ic_lock")) {
                            if let item = initialViewModel.constantsItems?.first(where: { $0.constantType == .privacy }) {
                                appRouter.navigate(to: .constant(item))
                            }
                        }

                        Divider()

                        settingsRow(title: "تسجيل الخروج", icon: .system(name: "rectangle.portrait.and.arrow.right")) {
                            logout()
                        }

                        settingsRow(title: "حذف الحساب", icon: .system(name: "trash")) {
                            deleteAccount()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top)
            }
        }
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                VStack(alignment: .leading) {
                    Text("المزيد 🚗")
                        .customFont(weight: .bold, size: 20)
                    Text("الإعدادات والتحكم بتفاصيل الحساب!")
                        .customFont(weight: .regular, size: 10)
                }
                .foregroundColor(Color.black222020())
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Image("ic_bell")
                    .onTapGesture {
                        appRouter.navigate(to: .notifications)
                    }
            }
        }
        .onAppear {
            initialViewModel.fetchConstantsItems()
        }
        .bindLoadingState(initialViewModel.state, to: appRouter)
        .bindLoadingState(authViewModel.state, to: appRouter)
    }

    @ViewBuilder
    func settingsRow(title: String, icon: RowIcon, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconView(icon)
                    .frame(width: 22, height: 22)
                Text(title)
                Spacer()
                Image(systemName: "chevron.left")
                    .foregroundColor(.gray)
            }
            .customFont(weight: .medium, size: 16)
            .foregroundColor(title == "حذف الحساب" ? .red : .black)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    func iconView(_ icon: RowIcon) -> some View {
        switch icon {
        case .system(let name):
            Image(systemName: name)
                .resizable()
                .aspectRatio(contentMode: .fit)
        case .asset(let name):
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    private func logout() {
        appRouter.showAlert(
            title: "هل تريد تسجيل الخروج؟",
            message: "سيتم تسجيل خروجك من التطبيق.",
            okTitle: "تسجيل الخروج",
            cancelTitle: "رجوع",
            onOK: {
                authViewModel.logoutUser {
                    appRouter.show(.success, message: "تم تسجيل الخروج بنجاح")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        appState.currentTab = .home
                    }
                }
            },
            onCancel: {
                print("تم إلغاء تسجيل الخروج")
            }
        )
    }

    private func deleteAccount() {
        appRouter.showAlert(
            title: "حذف الحساب نهائيًا",
            message: "هل أنت متأكد أنك تريد حذف حسابك؟ سيتم فقد جميع بياناتك ولن تستطيع استرجاعها!",
            okTitle: "نعم، احذف الحساب",
            cancelTitle: "تراجع",
            onOK: {
                authViewModel.deleteAccount {
                    appRouter.show(.success, message: "تم حذف الحساب بنجاح")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        appState.currentTab = .home
                    }
                }
            },
            onCancel: {
                print("تم إلغاء حذف الحساب")
            }
        )
    }
}

// MARK: - RowIcon Helper
enum RowIcon {
    case system(name: String)
    case asset(name: String)
}

// MARK: - ProfileCardView
struct ProfileCardView: View {
    let name: String
    let phone: String
    let imageUrl: String?
    @EnvironmentObject var appRouter: AppRouter

    var body: some View {
        ZStack {
            Color.primary()
                .cornerRadius(16)
                .frame(height: 100)
                .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)

            HStack {
                HStack(spacing: 10) {
                    if let urlStr = imageUrl, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            Image("profile")
                                .resizable()
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    } else {
                        Image("profile")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .customFont(weight: .bold, size: 20)
                            .foregroundColor(.white)
                        Text(phone)
                            .customFont(weight: .regular, size: 14)
                            .foregroundColor(.white)
                    }
                }
                .padding(.leading, 16)

                Spacer()

                Button {
                    appRouter.navigate(to: .editProfile)
                } label: {
                    Image(systemName: "pencil")
                        .customFont(weight: .medium, size: 22)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 100)
        .padding(.horizontal, 8)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppRouter())
        .environmentObject(UserSettings())
        .environmentObject(AppState())
}
