import SwiftUI
import PopupView

struct RegistrationWorkInfoView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @Binding var showSpecialtyPopup: Bool

    var selectedCategory: Category? {
        viewModel.allCategories.first(where: { $0.id == viewModel.mainCategoryId })
    }

    var body: some View {
        VStack(spacing: 28) {
            RegistrationStepHeader(
                title: "تفاصيل العمل",
                subtitle: "اختر التخصص الرئيسي المناسب لمهاراتك."
            )

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

                        if let selectedSub = cat.sub?.first(where: { $0.id == viewModel.subcategory }) {
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
    }
}

struct SelectedCategoryView: View {
    let cat: Category
    let onRemove: () -> Void

    var body: some View {
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
                .customFont(weight: .bold, size: 15)
                .foregroundColor(.primary())
            Button(action: onRemove) {
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
    }
}

struct SelectedSubCategoryView: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "tag.fill")
                .foregroundColor(.blue)

            Text(title)
                .customFont(weight: .medium, size: 14)
                .foregroundColor(.primary)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.75))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.blue.opacity(0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.blue, lineWidth: 1)
        )
    }
}

struct AddCategoryButtonLabel: View {
    var isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(Color.yellowF8B22A())
            Text(isSelected ? "تغيير التخصص" : "إضافة تخصص")
                .customFont(weight: .medium, size: 15)
                .foregroundColor(Color.primaryBlack())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.yellowF8B22A(), lineWidth: 1.5)
        )
    }
}

#Preview {
    let vm = RegistrationViewModel()
    vm.allCategories = [
        Category(id: "1", title: "مصمم", description: nil, image: nil, sub: []),
        Category(id: "2", title: "مهندس برمجيات", description: nil, image: nil, sub: [])
    ]
    vm.mainCategoryId = "1"
    return RegistrationWorkInfoView(viewModel: vm, showSpecialtyPopup: .constant(false))
}
