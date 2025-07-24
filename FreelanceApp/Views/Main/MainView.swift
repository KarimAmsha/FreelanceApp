import SwiftUI
import PopupView
import FirebaseMessaging

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var viewModel: InitialViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var registrationViewModel: RegistrationViewModel

    private var tabItems: [MainTabItem] {
        var items: [MainTabItem] = [
            MainTabItem(page: .home, iconSystemName: "house", title: "الرئيسية"),
            MainTabItem(page: .chat, iconSystemName: "message", title: "الرسائل", isNotified: true),
            MainTabItem(page: .projects, iconSystemName: "briefcase", title: "المشاريع"),
            MainTabItem(page: .more, iconSystemName: "line.3.horizontal", title: "المزيد")
        ]
        if settings.userRole == .company {
            items.insert(MainTabItem(page: .addService, iconSystemName: "plus.circle", title: "إضافة خدمة"), at: 2)
        }
        return items
    }

    var body: some View {
        NavigationStack(path: $appRouter.navPath) {
            ZStack {
                Color.background().ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer()
                    contentForPage(appState.currentTab)
                    MainTabBar(tabItems: tabItems)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(Color.background(), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AppRouter.Destination.self) {
                destinationView(destination: $0)
            }
            .onAppear {
                refreshFcmToken()
            }
        }
        .accentColor(.black)
    }

    @ViewBuilder
    func contentForPage(_ page: MainTab) -> some View {
        switch page {
        case .home:
            HomeView()
        case .chat:
            ChatListView(userId: settings.id ?? "")
        case .projects:
            settings.userRole == .company ? ProjectsView().eraseToAnyView() : ClientProjectsView().eraseToAnyView()
        case .addService:
            settings.id == nil ? CustomeEmptyView().eraseToAnyView() : AddServiceView().eraseToAnyView()
        case .more:
            settings.id == nil ? CustomeEmptyView().eraseToAnyView() : ProfileView().eraseToAnyView()
        }
    }

    @ViewBuilder
    func destinationView(destination: AppRouter.Destination) -> some View {
        switch destination {
        case .profile: ProfileView()
        case .editProfile: EditProfileView()
        case .changePassword: EmptyView()
        case .changePhoneNumber: PhoneChangeView().environmentObject(appRouter)
        case .contactUs: ContactUsView()
        case .constant(let item): ConstantView(item: .constant(item))
        case .addressBook: AddressBookView()
        case .addAddressBook: AddAddressView()
        case .editAddressBook(let item): EditAddressView(addressItem: item)
        case .addressBookDetails(let item): AddressDetailsView(addressItem: item)
        case .notifications: NotificationsView()
        case .notificationsSettings: NotificationsSettingsView()
        case .accountSettings: AccountSettingsView()
        case .freelancerList(let categoryId, let categoryTitle, let count):
            FreelancerListView(categoryId: categoryId, categoryTitle: categoryTitle, freelancersCount: count)
        case .freelancerProfile(let freelancer): FreelancerProfileView(freelancer: freelancer)
        case .serviceDetails: ServiceDetailsView()
        case .chat(let chatId, let userId): ChatDetailView(chatId: chatId, currentUserId: userId)
        case .selectMainSpecialty:
            MainSpecialtySelectionView(viewModel: registrationViewModel).environmentObject(appRouter)
        case .deliveryDetails: DeliveryDetailsView()
        case .earningsView: EarningsView()
        }
    }

    private func refreshFcmToken() {
        Messaging.messaging().token { token, _ in
            guard let token = token, let userId = settings.id else { return }
            let body = RefreshFcmRequest(id: userId, fcmToken: token)
            userViewModel.refreshFcmToken(body: body, onSuccess: {})
        }
    }
}

#Preview {
    MainView()
        .environmentObject(UserSettings())
        .environmentObject(AppState())
        .environmentObject(AppRouter())
}
