import SwiftUI
import PopupView

struct RegistrationWorkInfoView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @Binding var showSpecialtyPopup: Bool

    var selectedCategoriesString: String {
        viewModel.allCategories
            .filter { viewModel.selectedCategoryIds.contains($0.id ?? "") }
            .map { $0.title ?? "" }
            .joined(separator: "، ")
    }

    var body: some View {
        VStack(spacing: 24) {
            RegistrationStepHeader(
                title: "تفاصيل العمل",
                subtitle: "قم بإدخال تفاصيل العمل الصحيحة والتي تُجيدها في مجالك للحصول على فرص أعلى."
            )
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("التخصصات المختارة")
                        .font(.subheadline)
                        .foregroundColor(.black)

                    Button {
                        showSpecialtyPopup = true
                    } label: {
                        HStack {
                            if viewModel.selectedCategoryIds.isEmpty {
                                Text("اختر تخصص أو أكثر")
                                    .foregroundColor(.gray)
                            } else {
                                Text(selectedCategoriesString)
                                    .foregroundColor(.primaryBlack())
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3))
                        )
                    }

                }
            }
            Spacer()
        }
        .padding()
        .background(Color.background())
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            if viewModel.allCategories.isEmpty {
                viewModel.getMainCategories(q: "")
            }
        }
        .popup(isPresented: $showSpecialtyPopup) {
            SpecialtySelectionPopup(
                isPresented: $showSpecialtyPopup,
                categories: viewModel.allCategories,
                selectedCategoryIds: $viewModel.selectedCategoryIds
            )
        } customize: {
            $0
                .type(.default)
                .position(.bottom)
                .animation(.easeInOut)
                .closeOnTapOutside(true)
                .closeOnTap(false)
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
    vm.selectedCategoryIds = ["1"]
    return RegistrationWorkInfoView(viewModel: vm, showSpecialtyPopup: .constant(false))
}
