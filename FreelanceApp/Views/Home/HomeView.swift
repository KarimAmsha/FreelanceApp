//
//  HomeView.swift
//  Wishy
//
//  Created by Karim Amsha on 28.04.2024.
//

import SwiftUI
import SkeletonUI
import RefreshableScrollView
import FirebaseMessaging

struct HomeView: View {
    @StateObject var viewModel = InitialViewModel()
    @EnvironmentObject var appRouter: AppRouter
    @State private var searchText: String = ""
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    @StateObject private var userViewModel = UserViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("المشاريع الفعالة")
                        .font(.system(size: 16, weight: .bold))

                    let user = UserSettings.shared.user
                    GeneralCardView(
                        title: "برمجة تطبيق",
                        rating: user?.rate ?? 0,
                        reviewer: user?.full_name ?? "بدون اسم",
                        completedProjects: 0,
                        price: user?.wallet?.formattedAsCurrency() ?? "$0",
                        date: user?.formattedDOB ?? "",
                        status: user?.isVerify == true ? "موثّق" : "غير موثّق"
                    )
                }

                if let sliders = viewModel.homeItems?.slider, !sliders.isEmpty {
                    SliderView(items: sliders, currentIndex: $currentIndex)
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("البحث بالتخصص")
                            .font(.system(size: 16, weight: .bold))
                            .padding()

                        if let categories = viewModel.homeItems?.category, !categories.isEmpty {
                            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 16), count: 2), spacing: 16) {
                                ForEach(categories) { category in
                                    CategoryCardView(category: category) {
                                        appRouter.navigate(to: .freelancerList(
                                            categoryId: category.id,
                                            categoryTitle: category.title,
                                            freelancersCount: category.users ?? 0
                                        ))
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            DefaultEmptyView(title: LocalizedStringKey.noDataFound)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: geometry.size.height)
        }
        .background(Color.background())
        .bindLoadingState(viewModel.state, to: appRouter)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    AsyncImageView(
                        width: 40,
                        height: 40,
                        cornerRadius: 10,
                        imageURL: UserSettings.shared.user?.image?.toURL(),
                        placeholder: Image(systemName: "person.fill"),
                        contentMode: .fill
                    )
                    VStack(alignment: .leading) {
                        Text("مرحباً \(UserSettings.shared.user?.full_name ?? "")! 👋")
                            .customFont(weight: .bold, size: 20)
                        Text(UserSettings.shared.user?.work ?? "-")
                            .customFont(weight: .regular, size: 10)
                    }
                    .foregroundColor(Color.black222020())
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Image("ic_bell")
                    .onTapGesture {
                        appRouter.navigate(to: .notifications)
                    }
            }
        }
        .onAppear {
            getHome()
            refreshFcmToken()
        }
    }

    func openWhatsApp() {
        let phoneNumber = viewModel.whatsAppContactItem?.Data ?? ""
        if let url = URL(string: "https://wa.me/\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    HomeView()
}

extension HomeView {
    func getHome() {
        viewModel.fetchHomeItems()
    }

    func refreshFcmToken() {
        Messaging.messaging().token { token, error in
            if let token = token {
                let request = RefreshFcmRequest(
                    id: UserSettings.shared.id ?? "",
                    fcmToken: token
                )

                userViewModel.refreshFcmToken(body: request, onSuccess: {
                    // النجاح
                })
            }
        }
    }
}

struct Category2: Identifiable {
    let id = UUID()
    let title: String
    let image: String
}

let sampleCategories: [Category2] = [
    .init(title: "التصميم", image: "design_image"),
    .init(title: "المجال المالي", image: "finance_image"),
    .init(title: "المجال الطبي", image: "medical_image"),
    .init(title: "التدريس", image: "teaching_image")
]

struct SliderView: View {
    let items: [SliderItem]
    @Binding var currentIndex: Int

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(items.indices, id: \.self) { i in
                let slider = items[i]
                ZStack(alignment: .bottomLeading) {
                    AsyncImageView(
                        width: UIScreen.main.bounds.width - 36,
                        height: 180,
                        cornerRadius: 18,
                        imageURL: slider.image.toURL(),
                        placeholder: Image(systemName: "photo"),
                        contentMode: .fill
                    )
                    .clipped()

                    LinearGradient(
                        gradient: Gradient(colors: [.black.opacity(0.0), .black.opacity(0.45)]),
                        startPoint: .top, endPoint: .bottom
                    )
                    .cornerRadius(18)
                    .frame(height: 180)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(slider.title ?? "")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if let desc = slider.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.93))
                                .lineLimit(2)
                        }
                    }
                    .padding(18)
                }
                .frame(width: UIScreen.main.bounds.width - 36, height: 180)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.vertical, 4)
                .tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 190)
        .padding(.horizontal, 18)
    }
}

struct CategoryCardView: View {
    let category: CategoryItem
    let onTap: () -> Void

    var body: some View {
        VStack {
            AsyncImageView(
                width: .infinity,
                height: 120,
                cornerRadius: 10,
                imageURL: category.image?.toURL(),
                placeholder: Image(systemName: "photo"),
                contentMode: .fill
            )
            Text(category.title)
                .font(.system(size: 14, weight: .semibold))
            Text("\(category.users ?? 0) فريلانسر")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .onTapGesture { onTap() }
    }
}
