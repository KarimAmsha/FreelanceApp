import SwiftUI
import PopupView

struct MainSpecialtySelectionView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @StateObject var userViewModel = UserViewModel()
    @EnvironmentObject var appRouter: AppRouter
    @State private var showSpecialtyPopup = false
    @State private var didAppear = false

    private var selectedCategory: Category? {
        viewModel.allCategories.first(where: { $0.id == viewModel.mainCategoryId })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("اختر التخصص الرئيسي")
                .font(.title2.bold())
                .padding(.top, 32)

            VStack(spacing: 14) {
                if let cat = selectedCategory {
                    selectedCategoryView(cat: cat)
                } else if viewModel.isLoading {
                    ProgressView("جارٍ تحميل التخصصات...")
                        .padding(.vertical, 28)
                } else {
                    addCategoryButton
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.background())
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                navBarTitle
            }
        }
        .popup(isPresented: $showSpecialtyPopup) {
            SingleSpecialtyGridSelectionView(
                isPresented: $showSpecialtyPopup,
                categories: viewModel.allCategories,
                selectedCategoryId: Binding(
                    get: { viewModel.mainCategoryId },
                    set: { newValue in
                        guard let catId = newValue, catId != viewModel.mainCategoryId else { return }
                        updateMainCategory(to: catId)
                    }
                ),
                selectedSubCategoryId: .constant(nil) // أو مرر القيمة المناسبة إن وُجدت
            )
        } customize: {
            $0.type(.default)
              .position(.bottom)
              .animation(.easeInOut)
              .closeOnTapOutside(true)
              .backgroundColor(Color.black.opacity(0.3))
              .isOpaque(true)
              .useKeyboardSafeArea(true)
        }
        .overlay {
            if userViewModel.state.isLoading {
                loadingOverlay
            }
        }
        .onAppear {
            if !didAppear {
                didAppear = true
                syncInitialCategory()
            }
        }
    }

    // MARK: - Components

    private var navBarTitle: some View {
        HStack(spacing: 12) {
            Button { appRouter.navigateBack() } label: {
                Image(systemName: "chevron.backward")
                    .foregroundColor(.black)
            }
            Text("تغيير التخصص الرئيسي")
                .customFont(weight: .bold, size: 20)
                .foregroundColor(.black222020())
        }
    }

    private func selectedCategoryView(cat: Category) -> some View {
        HStack(spacing: 14) {
            if let urlStr = cat.image, let url = URL(string: urlStr) {
                AsyncImage(url: url) { img in
                    img.resizable()
                } placeholder: {
                    Color.gray.opacity(0.13)
                }
                .frame(width: 38, height: 38)
                .clipShape(Circle())
            }

            Text(cat.title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Button {
                showSpecialtyPopup = true
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.yellowF8B22A())
            }
        }
        .padding()
        .background(Color.yellowF8B22A().opacity(0.13))
        .cornerRadius(16)
    }

    private var addCategoryButton: some View {
        Button {
            showSpecialtyPopup = true
        } label: {
            Label("إضافة تخصص رئيسي", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundColor(.yellowF8B22A())
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellowF8B22A(), lineWidth: 1.5)
                )
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            ProgressView("جاري تحديث التخصص ...")
                .padding()
                .background(Color.white)
                .cornerRadius(18)
                .shadow(radius: 6)
        }
    }

    // MARK: - Logic

    private func syncInitialCategory() {
        if let mainCat = UserSettings.shared.user?.mainSpecialtyId {
            viewModel.mainCategoryId = mainCat
        }
        if viewModel.allCategories.isEmpty {
            viewModel.getMainCategories()
        }
    }

    private func updateMainCategory(to catId: String) {
        showSpecialtyPopup = false
        userViewModel.updateUserSpecialty(to: catId) {
            viewModel.mainCategoryId = catId
            appRouter.show(.success, message: "تم تحديث التخصص بنجاح")
        }
    }
}
