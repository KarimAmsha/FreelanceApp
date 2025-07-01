import SwiftUI
import PopupView

struct RegistrationWorkInfoView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @Binding var showSpecialtyPopup: Bool

    var selectedCategories: [Category] {
        viewModel.allCategories.filter { viewModel.selectedCategoryIds.contains($0.id ?? "") }
    }

    var body: some View {
        VStack(spacing: 28) {
            RegistrationStepHeader(
                title: "تفاصيل العمل",
                subtitle: "اختر التخصصات بدقة، يمكنك إضافة أكثر من تخصص مناسب لمهاراتك."
            )

            VStack(alignment: .leading, spacing: 16) {
                Text("تخصصاتك المختارة")
                    .font(.headline)
                    .foregroundColor(.primary)

                // شيبس التخصصات
                if selectedCategories.isEmpty {
                    Text("لم يتم اختيار تخصصات بعد")
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                } else {
                    // عرض شيبس تخصصات مختارة مع إمكانية الإزالة
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(selectedCategories, id: \.id) { cat in
                                HStack(spacing: 4) {
                                    if let urlStr = cat.image, let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { img in
                                            img.resizable()
                                        } placeholder: {
                                            Color.gray.opacity(0.2)
                                        }
                                        .frame(width: 22, height: 22)
                                        .clipShape(Circle())
                                    }
                                    Text(cat.title ?? "")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.primary)
                                    Button {
                                        withAnimation {
                                            viewModel.selectedCategoryIds.removeAll { $0 == cat.id }
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.red.opacity(0.75))
                                            .padding(.leading, 2)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.yellowF8B22A().opacity(0.15))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.yellowF8B22A(), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // زر إضافة تخصص
                Button {
                    showSpecialtyPopup = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color.yellowF8B22A())
                        Text("إضافة تخصص")
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
