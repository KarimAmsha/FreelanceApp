import SwiftUI
import Combine

struct FreelancerListView: View {
    @EnvironmentObject var appRouter: AppRouter

    let categoryId: String
    let categoryTitle: String
    let freelancersCount: Int

    @StateObject private var viewModel: FreelancerListViewModel
    @StateObject private var locationManager = LocationManager.shared
    @State private var showFilterSheet = false
    @State private var searchCancellable: AnyCancellable?

    // Constructor يدعم الـ StateObject
    init(categoryId: String, categoryTitle: String, freelancersCount: Int) {
        self.categoryId = categoryId
        self.categoryTitle = categoryTitle
        self.freelancersCount = freelancersCount
        _viewModel = StateObject(wrappedValue: FreelancerListViewModel(categoryId: categoryId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar + زر الفلترة
            HStack(spacing: 12) {
                TextField("ابحث باسم الفريلانسر", text: $viewModel.searchText)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        HStack {
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                                .padding(.trailing, 12)
                        }
                    )
                    .onChange(of: viewModel.searchText) { _ in debounceSearch() }

                Button(action: { showFilterSheet = true }) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .padding()
                        .foregroundColor(.black151515())
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .sheet(isPresented: $showFilterSheet) {
                    FilterSheetView(viewModel: viewModel)
                        .presentationDetents([.medium, .large])
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // النتائج أو التحميل أو "لا يوجد نتائج"
            if viewModel.isLoading && viewModel.freelancers.isEmpty {
                ProgressView().padding()
            } else if viewModel.freelancers.isEmpty {
                Text("لا يوجد نتائج.").foregroundColor(.gray).padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.freelancers) { freelancer in
                            Button(action: {
                                appRouter.navigate(to: .freelancerProfile(freelancer: freelancer))
                            }) {
                                FreelancerRowView(freelancer: freelancer)
                            }
                            .onAppear {
                                viewModel.loadMoreIfNeeded(currentItem: freelancer)
                            }
                        }
                        if viewModel.isFetchingMoreData {
                            ProgressView().padding()
                        }
                    }
                    .padding()
                }
                .refreshable { viewModel.refresh() }
            }
            Spacer()
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text(categoryTitle)
                            .font(.system(size: 18, weight: .bold))
                        Text("+\(freelancersCount) فريلانسر")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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
            // اطلب الموقع إذا لم يكن محدد
            if locationManager.latitude == 0 || locationManager.longitude == 0 {
                locationManager.requestLocationOnce()
            } else {
                // مرر اللوكيشن للفيو موديل مباشرة
                viewModel.userLatitude = locationManager.latitude
                viewModel.userLongitude = locationManager.longitude
                if viewModel.freelancers.isEmpty {
                    viewModel.fetchFreelancers(page: 0)
                }
            }
        }
        .onChange(of: locationManager.latitude) { lat in
            if lat != 0 {
                viewModel.userLatitude = lat
                if viewModel.freelancers.isEmpty {
                    viewModel.fetchFreelancers(page: 0)
                }
            }
        }
        .onChange(of: locationManager.longitude) { lng in
            if lng != 0 {
                viewModel.userLongitude = lng
            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
    }

    // Debounce بحث بالاسم
    func debounceSearch() {
        searchCancellable?.cancel()
        searchCancellable = Just(())
            .delay(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { _ in viewModel.refresh() }
    }
}

import SwiftUI

struct FilterSheetView: View {
    @ObservedObject var viewModel: FreelancerListViewModel
    @Environment(\.presentationMode) var presentationMode

    let cardBG = Color(.systemGray6)

    var body: some View {
        VStack(spacing: 18) {
//            // زر إغلاق X أعلى يسار الشاشة
//            HStack {
//                Button(action: {
//                    presentationMode.wrappedValue.dismiss()
//                }) {
//                    Image(systemName: "xmark")
//                        .font(.system(size: 22, weight: .bold))
//                        .foregroundColor(.gray)
//                        .frame(width: 38, height: 38)
//                        .background(
//                            Circle().fill(Color.white)
//                                .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 1)
//                        )
//                }
//                .padding(.top, 12)
//                .padding(.leading, 6)
//                Spacer()
//            }
//

            Capsule()
                .frame(width: 42, height: 5)
                .foregroundColor(Color.gray.opacity(0.15))
                .padding(.top, 8)

            Text("تصفية النتائج")
                .customFont(weight: .bold, size: 14)
                .padding(.top, 8)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("لتسهيل عملية البحث عليك يجب اختيار الفلاتر المناسبة")
                .customFont(weight: .regular, size: 12)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)

            // ---- Card Filter ----
            VStack(spacing: 24) {
//                GridFilterRow(
//                    title: "المشاريع المكتملة",
//                    from: $viewModel.completedProjectsFrom,
//                    to: $viewModel.completedProjectsTo,
//                    unit: nil
//                )
                GridFilterRow(
                    title: "المسافة",
                    from: $viewModel.distanceFrom,
                    to: $viewModel.distanceTo,
                    unit: "كيلو متر"
                )
//                GridFilterRow(
//                    title: "عدد الخدمات",
//                    from: $viewModel.completedServicesFrom,
//                    to: $viewModel.completedServicesTo,
//                    unit: nil
//                )
                GridFilterRow(
                    title: "الأرباح",
                    from: $viewModel.profitFrom,
                    to: $viewModel.profitTo,
                    unit: nil
                )

                // التقييم
                VStack(alignment: .leading, spacing: 10) {
                    Text("التقييم")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 16) {
                        ForEach(0..<5) { idx in
                            Image(systemName: idx < viewModel.rateTo ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundColor(.yellow)
                                .scaleEffect(idx < viewModel.rateTo ? 1.2 : 1.0)
                                .animation(.spring(), value: viewModel.rateTo)
                                .onTapGesture {
                                    withAnimation { viewModel.rateTo = idx + 1 }
                                }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 8)
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)

            Spacer()

            Button(action: {
                viewModel.refresh()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("تطبيق الفلاتر")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.primary())
                    .cornerRadius(12)
            }
            .padding(.vertical, 12)
            .shadow(color: Color.primary().opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
        .background(cardBG.ignoresSafeArea())
    }
}

// MARK: - عنصر جريد من خانتين
struct GridFilterRow: View {
    var title: String
    @Binding var from: Int
    @Binding var to: Int
    var unit: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .customFont(weight: .medium, size: 14)
                    .foregroundColor(.black)
                Spacer()
                if let unit = unit {
                    Text("\"\(unit)\"")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            HStack(spacing: 10) {
                FilterInputBox(value: $from, hint: "من")
                FilterInputBox(value: $to, hint: "الى")
            }
        }
    }
}

// MARK: - مربع إدخال احترافي
struct FilterInputBox: View {
    @Binding var value: Int
    var hint: String

    var body: some View {
        TextField(hint, value: $value, formatter: NumberFormatter())
            .keyboardType(.numberPad)
            .frame(width: 70, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                    .background(Color.white.cornerRadius(12))
            )
            .customFont(weight: .regular, size: 12)
            .multilineTextAlignment(.center)
            .shadow(color: Color.black.opacity(0.01), radius: 2, x: 0, y: 1)
    }
}

// --- Example Preview
#Preview {
    FreelancerListView(categoryId: "65ad02286942426c04e13994", categoryTitle: "التصميم", freelancersCount: 1500)
        .environmentObject(AppRouter())
}

struct FreelancerRowView: View {
    let freelancer: Freelancer

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AsyncImageView(
                    width: 44,
                    height: 44,
                    cornerRadius: 22,
                    imageURL: freelancer.image?.toURL(),
                    placeholder: Image(systemName: "person.fill"),
                    contentMode: .fill
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(freelancer.full_name ?? "اسم غير متوفر")
                        .font(.headline)
                    Text(freelancer.title ?? "")
                        .font(.caption)
                }
                .foregroundColor(.black151515())
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", freelancer.rating ?? 0.0))
                        .foregroundColor(.black151515())
                }
                .font(.subheadline)
            }
            Text(freelancer.bio ?? "بدون نبذة")
                .font(.callout)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
            HStack(spacing: 12) {
                Label("\(freelancer.completedServices ?? 0) خدمات", systemImage: "square.grid.2x2")
                    .font(.caption)
                    .foregroundColor(.gray)
                Label("\(freelancer.completedProjects ?? 0) مشاريع مكتملة", systemImage: "checkmark.seal")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                if let price = freelancer.price {
                    Text("$\(Int(price))")
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
