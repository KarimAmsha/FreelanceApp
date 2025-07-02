//
//  ProfileView.swift
//  Wishy
//
//  Created by Karim Amsha on 30.04.2024.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var initialViewModel = InitialViewModel(errorHandling: ErrorHandling())
    @StateObject private var authViewModel = AuthViewModel(errorHandling: ErrorHandling())
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var userSettings: UserSettings

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Profile Card
                    ProfileCardView(
                        name: userSettings.user?.full_name ?? "اسم المستخدم",
                        phone: userSettings.user?.phone_number ?? "55 ### ####",
                        imageUrl: userSettings.user?.image
                    )

                    // Settings List
                    VStack(spacing: 0) {
                        settingsRow(title: "أرباحي", icon: "bag") {
                            appRouter.navigate(to: .earningsView)
                        }

                        settingsRow(title: "الإشعارات", icon: "bell") {
                            appRouter.navigate(to: .notificationsSettings)
                        }

                        settingsRow(title: "إعدادات الحساب", icon: "gearshape") {
                            appRouter.navigate(to: .accountSettings)
                        }

                        settingsRow(title: "المساعدة", icon: "questionmark.bubble") {
                            appRouter.navigate(to: .editProfile)
                        }
                        settingsRow(title: "تسجيل الخروج", icon: "rectangle.portrait.and.arrow.right") {
                            logout()
                        }
                        settingsRow(title: "حذف الحساب", icon: "trash") {
                            deleteAccount()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden()
        .background(Color.background())
//        .tabBar()
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
            getConstants()
        }
    }
    
    @ViewBuilder
    func settingsRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                Image(systemName: "chevron.left")
            }
            .foregroundColor(title == "حذف الحساب" ? .red : .black)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppRouter())
        .environmentObject(UserSettings())
}

extension ProfileView {
    private func getConstants() {
        initialViewModel.fetchConstantsItems()
    }

    private func logout() {
        let alertModel = AlertModel(icon: "",
                                    title: LocalizedStringKey.logout,
                                    message: LocalizedStringKey.logoutMessage,
                                    hasItem: false,
                                    item: nil,
                                    okTitle: LocalizedStringKey.logout,
                                    cancelTitle: LocalizedStringKey.back,
                                    hidesIcon: true,
                                    hidesCancel: true) {
            authViewModel.logoutUser {
                appState.currentPage = .home
            }
            appRouter.dismissPopup()
        } onCancelAction: {
            appRouter.dismissPopup()
        }
        
        appRouter.togglePopup(.alert(alertModel))
    }
    
    private func deleteAccount() {
        let alertModel = AlertModel(
            icon: "trash",
            isSystemImage: true,
            title: "حذف الحساب نهائيًا",
            message: "هل أنت متأكد أنك تريد حذف حسابك؟ سيتم فقد جميع بياناتك ولن تستطيع استرجاعها!",
            hasItem: false,
            item: nil,
            okTitle: "نعم، احذف الحساب",
            cancelTitle: "تراجع",
            hidesIcon: false,
            hidesCancel: false
        ) {
            authViewModel.deleteAccount {
                appState.currentPage = .home
            }
            appRouter.dismissPopup()
        } onCancelAction: {
            appRouter.dismissPopup()
        }

        appRouter.togglePopup(.alert(alertModel))
    }
}

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
                // البيانات على اليمين
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
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text(phone)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                    }
                    
                }
                .padding(.leading, 16)

                Spacer()
                
                // زر القلم أوتلاين على اليسار
                Button(action: {
                    appRouter.navigate(to: .editProfile)
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 22, weight: .medium))
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

// معاينة:
struct ProfileCardView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileCardView(
            name: "جاد سعيد",
            phone: "100 مشروع مكتمل",
            imageUrl: "https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg"
        )
        .background(Color(.systemBackground))
        .previewLayout(.sizeThatFits)
    }
}
