import SwiftUI

// Enum for Tabs
enum FreelancerTab {
    case services, portfolio, about, reviews
}

struct FreelancerProfileView: View {
    @EnvironmentObject var appRouter: AppRouter
    let freelancer: Freelancer
    @State private var selectedTab: FreelancerTab = .services

    // استخدم هذا لتفادي مشكلة type-check
    private var selectedTabView: some View {
        switch selectedTab {
        case .services:
            return AnyView(
                FreelancerServicesTab(freelancer: freelancer) {
                    appRouter.navigate(to: .serviceDetails)
                }
            )
        case .portfolio:
            return AnyView(FreelancerPortfolioTab(freelancer: freelancer))
        case .about:
            return AnyView(FreelancerAboutTab(freelancer: freelancer))
        case .reviews:
            return AnyView(FreelancerReviewsTab(freelancer: freelancer))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Profile Info
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(freelancer.full_name ?? "اسم غير متوفر")
                                .font(.headline)
                            Text(freelancer.title ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                            if let joined = freelancer.joinedAtFormatted {
                                Text("انضم بتاريخ: \(joined)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        AsyncImageView(
                            width: 50,
                            height: 50,
                            cornerRadius: 25,
                            imageURL: freelancer.image?.toURL(),
                            placeholder: Image(systemName: "person.crop.circle.fill"),
                            contentMode: .fill
                        )
                    }
                    .padding(.horizontal)

                    // Profile Completion (مثال ثابت، عدل لو عندك داتا)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("اكمال الملف الشخصي")
                                .font(.caption)
                            Spacer()
                            Text("95%")
                                .font(.caption)
                        }
                        ProgressView(value: 0.95)
                            .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                    }
                    .padding(.horizontal)

                    // Tabs
                    HStack(spacing: 0) {
                        TabItem(title: "الخدمات", selected: selectedTab == .services)
                            .onTapGesture { selectedTab = .services }
                        TabItem(title: "معرض الاعمال", selected: selectedTab == .portfolio)
                            .onTapGesture { selectedTab = .portfolio }
                        TabItem(title: "نبذة واحصائيات", selected: selectedTab == .about)
                            .onTapGesture { selectedTab = .about }
                        TabItem(title: "المراجعات", selected: selectedTab == .reviews)
                            .onTapGesture { selectedTab = .reviews }
                    }
                    .padding(.top)

                    // Tab Content
                    selectedTabView
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color.background())
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.black)
                    }
                    Text(freelancer.full_name ?? "اسم غير متوفر")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Image("ic_bell")
                    .onTapGesture {
                        appRouter.navigate(to: .notifications)
                    }
            }
        }
    }
}

struct TabItem: View {
    let title: String
    let selected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: selected ? .bold : .regular))
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(selected ? Color.white : Color.clear)
            .overlay(
                Rectangle()
                    .frame(height: selected ? 2 : 0)
                    .foregroundColor(.yellow)
                    .padding(.top, 40)
            )
    }
}

struct FreelancerServicesTab: View {
    let freelancer: Freelancer
    var onServiceTap: (() -> Void)? = nil

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(freelancer.services ?? []) { service in
                VStack(alignment: .leading, spacing: 8) {
                    AsyncImageView(
                        width: nil,
                        height: 120,
                        cornerRadius: 8,
                        imageURL: service.image?.toURL(),
                        placeholder: Image(systemName: "photo"),
                        contentMode: .fill
                    )
                    Text(service.title ?? "")
                        .font(.system(size: 12))
                        .lineLimit(2)
                    HStack {
                        Text("$\(Int(service.price ?? 0))")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary())
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        Spacer()
                        Label(String(format: "%.1f", service.rating ?? 0.0), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(8)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .onTapGesture {
                    onServiceTap?()
                }
            }
        }
        .padding(.horizontal)
    }
}

struct FreelancerPortfolioTab: View {
    let freelancer: Freelancer
    var body: some View {
        VStack(spacing: 8) {
            ForEach(freelancer.portfolio ?? []) { item in
                HStack(spacing: 12) {
                    AsyncImageView(
                        width: 80,
                        height: 80,
                        cornerRadius: 8,
                        imageURL: item.image?.toURL(),
                        placeholder: Image(systemName: "photo"),
                        contentMode: .fill
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title ?? "")
                            .font(.subheadline)
                            .bold()
                        Text(item.description ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(8)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.horizontal)
    }
}

struct FreelancerAboutTab: View {
    let freelancer: Freelancer
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("نبذة عن الفريلانسر")
                .font(.headline)
            Text(freelancer.bio ?? "هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة.")
                .font(.body)
                .foregroundColor(.gray)

            Divider().padding(.vertical, 8)
            Text("احصائيات")
                .font(.headline)
            HStack {
                VStack {
                    Text("+\(freelancer.completedProjects ?? 0)")
                        .bold()
                    Text("مشروع")
                        .font(.caption)
                }
                Spacer()
                VStack {
                    Text("+\(freelancer.clientsCount ?? 0)")
                        .bold()
                    Text("عميل")
                        .font(.caption)
                }
                Spacer()
                VStack {
                    Text(String(format: "%.1f★", freelancer.rating ?? 0.0))
                        .bold()
                    Text("تقييم")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct FreelancerReviewsTab: View {
    let freelancer: Freelancer
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(freelancer.reviews ?? []) { review in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        AsyncImageView(
                            width: 40,
                            height: 40,
                            cornerRadius: 20,
                            imageURL: review.userImage?.toURL(),
                            placeholder: Image(systemName: "person.fill"),
                            contentMode: .fill
                        )
                        VStack(alignment: .leading) {
                            Text(review.userName ?? "مستخدم")
                                .bold()
                            Text(review.userTitle ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Label(String(format: "%.1f", review.rating ?? 0.0), systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    Text(review.text ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.horizontal)
    }
}

// Preview
#Preview {
    let mockFreelancer = Freelancer(
        id: "1",
        full_name: "أحمد العزايزة",
        title: "مصمم UX/UI",
        bio: "مصمم شغوف بخبرة أكثر من 6 سنوات في مجالات البرمجة والتصميم وخدمات البراندنج.",
        image: "https://randomuser.me/api/portraits/men/32.jpg",
        rating: 4.9,
        completedProjects: 28,
        completedServices: 17,
        price: 250,
        joinedAt: "2024-10-20T13:00:00Z",
        portfolio: [
            PortfolioItem(id: "1", title: "تطبيق عقارات ليبيا", description: "تطبيق متكامل لإدارة العقارات في ليبيا.", image: nil),
            PortfolioItem(id: "2", title: "تصميم هوية مطعم", description: "هوية كاملة مع مواقع التواصل.", image: nil)
        ],
        services: [
            Service(id: "1", title: "تصميم بوستات سوشيال", image: nil, price: 10, rating: 4.7),
            Service(id: "2", title: "تصميم شعارات احترافية", image: nil, price: 15, rating: 4.8)
        ],
        reviews: [
            Review(id: "1", userName: "محمد ياسين", userTitle: "عميل", userImage: nil, rating: 4.9, text: "خدمة ممتازة وسريعة. سعيد بالتعامل."),
            Review(id: "2", userName: "سارة منصور", userTitle: "عميلة", userImage: nil, rating: 4.7, text: "مصمم محترف وتواصل جيد. أنصح به.")
        ],
        clientsCount: 120
    )
    FreelancerProfileView(freelancer: mockFreelancer)
        .environmentObject(AppRouter())
}
