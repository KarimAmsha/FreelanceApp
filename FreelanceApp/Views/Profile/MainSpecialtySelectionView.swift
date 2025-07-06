import SwiftUI
import PopupView

struct MainSpecialtySelectionView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @StateObject var userViewModel = UserViewModel(errorHandling: ErrorHandling())
    @EnvironmentObject var appRouter: AppRouter

    @State private var showSpecialtyPopup = false
    @State private var isUpdating = false

    // التخصص الحالي من قائمة التصنيفات
    private var selectedCategory: Category? {
        viewModel.allCategories.first(where: { $0.id == viewModel.mainCategoryId })
    }

    // عند أول ظهور: جلب التصنيفات وتحديد التخصص الحالي من بيانات المستخدم
    private func syncInitialCategory() {
        print("1111 \(userViewModel.user)")
        print("2222 \(UserSettings.shared.user)")
        print("3333 \(UserSettings.shared.user?.mainSpecialtyId)")

        if let mainCat = UserSettings.shared.user?.mainSpecialtyId {
            viewModel.mainCategoryId = mainCat
        }
        if viewModel.allCategories.isEmpty {
            viewModel.getMainCategories()
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("اختر التخصص الرئيسي")
                .font(.title2.bold())
                .padding(.top, 32)

            VStack(spacing: 14) {
                if let cat = selectedCategory {
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
                } else if viewModel.isLoading {
                    ProgressView("جارٍ تحميل التخصصات...")
                        .padding(.vertical, 28)
                } else {
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
            }

            Spacer()
        }
        .padding()
        .background(Color.background())
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 12) {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.black)
                    }

                    Text("تغيير التخصص الرئيسي")
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(.black222020())
                }
            }
        }
        // Popup اختيار تخصص رئيسي من جريد
        .popup(isPresented: $showSpecialtyPopup) {
            SingleSpecialtyGridSelectionView(
                isPresented: $showSpecialtyPopup,
                categories: viewModel.allCategories,
                selectedCategoryId: Binding(
                    get: { viewModel.mainCategoryId },
                    set: { newValue in
                        guard let catId = newValue, catId != viewModel.mainCategoryId else { return }
                        showSpecialtyPopup = false
                        isUpdating = true

                        // --- بناء كل البيانات الحالية من اليوزر الحالي (userViewModel.user) ---
                        let user = UserSettings.shared.user
                        var params: [String: Any] = [
                            "full_name": user?.full_name ?? "",
                            "email": user?.email ?? "",
                            "lat": user?.lat ?? 0.0,
                            "lng": user?.lng ?? 0.0,
                        ]
                        // --- إضافة التخصص المختار حسب نوع المستخدم ---
                        let userRole = UserSettings.shared.userRole
                        if userRole == .personal {
                            params["category"] = catId
                        } else if userRole == .company {
                            params["work"] = catId
                        }

                        print("params \(params)")
                        // بعد نجاح التحديث مباشرة (في الـ callback)
                        
                        userViewModel.updateUserData(params: params) { message in
                            isUpdating = false
                            // التحديث الجديد مباشرةً من الـ userViewModel.user الجديد
                            if let newCatId = userViewModel.user?.category {
                                viewModel.mainCategoryId = newCatId
                            } else {
                                viewModel.mainCategoryId = catId
                            }
                            showMessage(message: message)
                        }
                    }
                )
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
        // سبينر تحميل أثناء التحديث
        .overlay {
            if isUpdating {
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
        .overlay(
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .overlay(
            MessageAlertObserverView(
                message: $userViewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .onAppear {
            syncInitialCategory()
        }
    }
    
    private func showMessage(message: String) {
        let alertModel = AlertModel(
            icon: "",
            title: "",
            message: message,
            hasItem: false,
            item: nil,
            okTitle: "تم",
            cancelTitle: "رجوع",
            hidesIcon: true,
            hidesCancel: true
        ) {
            appRouter.dismissPopup()
            appRouter.navigateBack()
        } onCancelAction: {
            appRouter.dismissPopup()
        }

        appRouter.togglePopup(.alert(alertModel))
    }
}
