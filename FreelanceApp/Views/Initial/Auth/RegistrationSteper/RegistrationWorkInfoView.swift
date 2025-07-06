import SwiftUI
import PopupView

struct RegistrationWorkInfoView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @Binding var showSpecialtyPopup: Bool

    // التخصص المختار
    var selectedCategory: Category? {
        viewModel.allCategories.first(where: { $0.id == viewModel.mainCategoryId })
    }

    var body: some View {
        VStack(spacing: 28) {
            RegistrationStepHeader(
                title: "تفاصيل العمل",
                subtitle: "اختر التخصص الرئيسي المناسب لمهاراتك، يمكنك تغييره لاحقًا من إعدادات الحساب."
            )

            VStack(alignment: .leading, spacing: 16) {
                Text("تخصصك المختار")
                    .font(.headline)
                    .foregroundColor(.primary)

                // عرض التخصص المختار أو رسالة عدم وجوده
                if let cat = selectedCategory {
                    HStack(spacing: 8) {
                        if let urlStr = cat.image, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { img in
                                img.resizable()
                            } placeholder: {
                                Color.gray.opacity(0.2)
                            }
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                        }
                        Text(cat.title ?? "")
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        Button {
                            // إزالة التخصص المختار
                            withAnimation {
                                viewModel.mainCategoryId = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.red.opacity(0.75))
                                .padding(.leading, 2)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Color.yellowF8B22A().opacity(0.13))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.yellowF8B22A(), lineWidth: 1)
                    )
                } else {
                    Text("لم يتم اختيار تخصص بعد")
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                }

                // زر إضافة/تغيير تخصص
                Button {
                    showSpecialtyPopup = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.yellowF8B22A())
                        Text(selectedCategory == nil ? "إضافة تخصص" : "تغيير التخصص")
                            .foregroundColor(Color.primaryBlack())
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.white)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.yellowF8B22A(), lineWidth: 1.5)
                    )
                    .shadow(color: Color.yellowF8B22A().opacity(0.04), radius: 2, x: 0, y: 1)
                }
                .padding(.top, 6)
            }

            Spacer()
        }
        .padding()
        .background(Color.background())
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            if viewModel.allCategories.isEmpty {
                viewModel.getMainCategories()
            }
        }
        .popup(isPresented: $showSpecialtyPopup) {
            SingleSpecialtyGridSelectionView(
                isPresented: $showSpecialtyPopup,
                categories: viewModel.allCategories,
                selectedCategoryId: $viewModel.mainCategoryId
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
    }
}

#Preview {
    let vm = RegistrationViewModel(errorHandling: ErrorHandling())
    // عينة بيانات للتجربة في البرفيو
    vm.allCategories = [
        Category(id: "1", title: "مصمم", description: nil, image: nil, sub: []),
        Category(id: "2", title: "مهندس برمجيات", description: nil, image: nil, sub: [])
    ]
    vm.mainCategoryId = "1"
    return RegistrationWorkInfoView(viewModel: vm, showSpecialtyPopup: .constant(false))
}
