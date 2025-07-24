//
//  FreelancerListView.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 19.07.2025.
//

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

    init(categoryId: String, categoryTitle: String, freelancersCount: Int) {
        self.categoryId = categoryId
        self.categoryTitle = categoryTitle
        self.freelancersCount = freelancersCount
        _viewModel = StateObject(wrappedValue: FreelancerListViewModel(categoryId: categoryId))
    }

    var body: some View {
        VStack(spacing: 0) {
            buildSearchBar()

            if viewModel.state.isLoading && viewModel.freelancers.isEmpty {
                ProgressView().padding()
            } else if viewModel.freelancers.isEmpty {
                DefaultEmptyView(title: "لا يوجد نتائج")
            } else {
                buildFreelancersList()
            }

            Spacer()
        }
        .background(Color.background())
        .navigationBarBackButtonHidden()
        .toolbar { buildToolbar() }
        .onAppear(perform: handleOnAppear)
        .onChange(of: locationManager.latitude, perform: updateLatitude)
        .onChange(of: locationManager.longitude, perform: updateLongitude)
        .bindLoadingState(viewModel.state, to: appRouter)
    }

    @ViewBuilder
    private func buildSearchBar() -> some View {
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
    }

    @ViewBuilder
    private func buildFreelancersList() -> some View {
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
        .refreshable {
            viewModel.refresh()
        }
    }

    private func handleOnAppear() {
        if locationManager.latitude == 0 || locationManager.longitude == 0 {
            locationManager.requestLocationOnce()
        } else {
            viewModel.userLatitude = locationManager.latitude
            viewModel.userLongitude = locationManager.longitude
            if viewModel.freelancers.isEmpty {
                viewModel.fetchFreelancers(page: 0)
            }
        }
    }

    private func updateLatitude(_ lat: Double) {
        if lat != 0 {
            viewModel.userLatitude = lat
            if viewModel.freelancers.isEmpty {
                viewModel.fetchFreelancers(page: 0)
            }
        }
    }

    private func updateLongitude(_ lng: Double) {
        if lng != 0 {
            viewModel.userLongitude = lng
        }
    }

    @ToolbarContentBuilder
    private func buildToolbar() -> some ToolbarContent {
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

    func debounceSearch() {
        searchCancellable?.cancel()
        searchCancellable = Just(())
            .delay(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { _ in viewModel.refresh() }
    }
}

// MARK: - FilterSheetView
struct FilterSheetView: View {
    @ObservedObject var viewModel: FreelancerListViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .frame(width: 42, height: 5)
                .foregroundColor(Color.gray.opacity(0.15))
                .padding(.top, 8)

            Text("تصفية النتائج")
                .customFont(weight: .bold, size: 14)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("اختر الفلاتر التي تناسبك للعثور على المستقل المناسب")
                .customFont(weight: .regular, size: 12)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 24) {
                GridFilterRow(
                    title: "المسافة",
                    from: Binding(get: {
                        viewModel.filters.distanceFrom
                    }, set: {
                        viewModel.filters.distanceFrom = $0
                    }),
                    to: Binding(get: {
                        viewModel.filters.distanceTo
                    }, set: {
                        viewModel.filters.distanceTo = $0
                    }),
                    unit: "كم"
                )

                GridFilterRow(
                    title: "الأرباح",
                    from: Binding(get: {
                        viewModel.filters.profitFrom
                    }, set: {
                        viewModel.filters.profitFrom = $0
                    }),
                    to: Binding(get: {
                        viewModel.filters.profitTo
                    }, set: {
                        viewModel.filters.profitTo = $0
                    }),
                    unit: nil
                )

                GridFilterRow(
                    title: "التقييم",
                    from: Binding(get: {
                        viewModel.filters.rateFrom
                    }, set: {
                        viewModel.filters.rateFrom = $0
                    }),
                    to: Binding(get: {
                        viewModel.filters.rateTo
                    }, set: {
                        viewModel.filters.rateTo = $0
                    }),
                    unit: nil
                )
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))

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
        }
        .padding(.horizontal)
        .background(Color(.systemGray6).ignoresSafeArea())
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
                Spacer()
                if let unit = unit {
                    Text("(\(unit))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            HStack(spacing: 10) {
                FilterInputBox(value: $from, hint: "من")
                FilterInputBox(value: $to, hint: "إلى")
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
