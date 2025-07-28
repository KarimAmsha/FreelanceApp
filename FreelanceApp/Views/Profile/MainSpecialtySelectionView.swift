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

    private var selectedSubcategory: SubCategory? {
        selectedCategory?.sub?.first(where: { $0.id == viewModel.subcategory })
    }

    var body: some View {
        VStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 16) {
                Text("تخصصك المختار")
                    .customFont(weight: .medium, size: 15)
                    .foregroundColor(.primary())

                if let cat = selectedCategory {
                    VStack(alignment: .leading, spacing: 8) {
                        SelectedCategoryView(cat: cat) {
                            withAnimation {
                                viewModel.mainCategoryId = nil
                                viewModel.subcategory = nil
                            }
                        }

                        if let selectedSub = selectedSubcategory {
                            SelectedSubCategoryView(title: selectedSub.title) {
                                withAnimation {
                                    viewModel.subcategory = nil
                                }
                            }
                        }
                    }
                } else {
                    Text("لم يتم اختيار تخصص بعد")
                        .customFont(weight: .regular, size: 13)
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                }

                Button(action: {
                    showSpecialtyPopup = true
                }) {
                    AddCategoryButtonLabel(isSelected: selectedCategory != nil)
                }
                .padding(.top, 6)
            }

            Spacer()

            PrimaryActionButton(
                title: "حفظ التخصص",
                isLoading: userViewModel.state.isLoading
            ) {
                updateMainCategoryAndSubcategory()
            }
            .disabled(viewModel.mainCategoryId == nil)
        }
        .padding()
        .background(Color.background())
        .environment(\.layoutDirection, .rightToLeft)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 12) {
                    Button { appRouter.navigateBack() } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.black)
                    }
                    VStack(alignment: .leading) {
                        Text("تغيير التخصص الرئيسي")
                            .customFont(weight: .bold, size: 18)
                        Text("اختر التخصص المناسب ليظهر في ملفك الشخصي.")
                            .customFont(weight: .medium, size: 14)
                    }
                    .foregroundColor(.black222020())
                }
            }
        }
        .bindLoadingState(userViewModel.state, to: appRouter)
        .onAppear {
            if !didAppear {
                didAppear = true
                syncInitialCategory()
            }
        }
        .popup(isPresented: $showSpecialtyPopup) {
            SingleSpecialtyGridSelectionView(
                isPresented: $showSpecialtyPopup,
                categories: viewModel.allCategories,
                selectedCategoryId: $viewModel.mainCategoryId,
                selectedSubCategoryId: $viewModel.subcategory
            )
        } customize: {
            $0
                .type(.default)
                .position(.bottom)
                .animation(.easeInOut)
                .closeOnTapOutside(true)
                .backgroundColor(Color.black.opacity(0.3))
                .isOpaque(true)
                .useKeyboardSafeArea(true)
        }
        .overlay {
            if userViewModel.state.isLoading {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    ProgressView("جاري تحديث التخصص ...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(18)
                        .shadow(radius: 6)
                }
            }
        }
    }

    // MARK: - Helpers

    private func syncInitialCategory() {
        viewModel.getMainCategories {
            applyInitialCategory()
        }
    }

    private func applyInitialCategory() {
        guard let user = UserSettings.shared.user else { return }

        // نعيّن الكاتيجوري مباشرة إذا متوفر
        if let catId = user.category, !catId.isEmpty {
            viewModel.mainCategoryId = catId
        }

        // نعيّن الساب كاتيجوري مباشرة إذا متوفر
        if let subId = user.subcategory, !subId.isEmpty {
            viewModel.subcategory = subId
        }

        // تحميل الكاتيجوريز إن لم تكن محمّلة
        if viewModel.allCategories.isEmpty {
            viewModel.getMainCategories()
        }

        debugPrint("✅ Main Category Applied:", viewModel.mainCategoryId ?? "nil")
        debugPrint("✅ Subcategory Applied:", viewModel.subcategory ?? "nil")
    }

    private func updateMainCategoryAndSubcategory() {
        guard let mainId = viewModel.mainCategoryId, !mainId.isEmpty else { return }

        userViewModel.updateUserSpecialty(
            to: viewModel.mainCategoryId,
            subCategoryId: viewModel.subcategory
        ) {
            appRouter.show(.success, message: "تم تحديث التخصص بنجاح")
        }
    }
}
