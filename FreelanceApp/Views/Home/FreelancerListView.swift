import SwiftUI
import Combine

struct FreelancerListView: View {
    @EnvironmentObject var appRouter: AppRouter

    // يتم تمرير الـ categoryId من الشاشة السابقة
    let categoryId: String
    let categoryTitle: String
    let freelancersCount: Int

    @StateObject private var viewModel: FreelancerListViewModel
    @State private var showFilterSheet = false

    // للـ debounce البحث
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
            // Search Bar
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
                    .onChange(of: viewModel.searchText) { _ in
                        debounceSearch()
                    }

                Button(action: {
                    showFilterSheet = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .padding()
                        .foregroundColor(.black151515())
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .sheet(isPresented: $showFilterSheet) {
                    FilterSheetView()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

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
                        // Loader عند تحميل المزيد
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
        .overlay(
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .onAppear {
            // أول تحميل إذا لم تحمل
            if viewModel.freelancers.isEmpty {
                viewModel.fetchFreelancers(page: 0)
            }
        }
    }

    // debounce للبحث وعدم الضغط كل حرف
    func debounceSearch() {
        searchCancellable?.cancel()
        searchCancellable = Just(())
            .delay(for: .milliseconds(400), scheduler: RunLoop.main)
            .sink { _ in
                viewModel.refresh()
            }
    }
}

// مثال واجهة الفلاتر Sheet (تعدل لاحقاً)
struct FilterSheetView: View {
    var body: some View {
        VStack {
            Text("فلترة الفريلانسرز")
                .font(.title2)
                .padding()
            Spacer()
            Text("هنا عناصر الفلاتر مستقبلاً...")
            Spacer()
            Button("إغلاق") {
                // أغلق الشيت من فوق .sheet
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .padding(.bottom)
        }
    }
}

// --- Example Preview
#Preview {
    FreelancerListView(categoryId: "65d77ad715529b1b256c5d02", categoryTitle: "التصميم", freelancersCount: 1500)
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
