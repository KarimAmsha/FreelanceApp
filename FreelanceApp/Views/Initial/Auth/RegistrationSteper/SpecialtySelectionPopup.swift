import SwiftUI

struct SpecialtySelectionPopup: View {
    @Binding var isPresented: Bool
    var categories: [Category]
    @Binding var selectedCategoryIds: [String]

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.top, 8)

            Text("التخصص الأساسي")
                .font(.title3.bold())
                .foregroundColor(.primary)

            Text("اختر تخصص أو أكثر (اضغط لإنهاء)")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if categories.isEmpty {
                ProgressView("جارٍ تحميل التخصصات...")
                    .padding(.vertical)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(categories) { item in
                            // 1. احفظ id في متغير محلي وغير اختياري
                            guard let itemId = item.id else { return AnyView(EmptyView()) }
                            let isSelected = selectedCategoryIds.contains(itemId)
                            // 2. استخدم المتغير المحلي في كل مكان
                            return AnyView(
                                Button {
                                    if isSelected {
                                        selectedCategoryIds.removeAll { $0 == itemId }
                                    } else {
                                        selectedCategoryIds.append(itemId)
                                    }
                                } label: {
                                    SpecialtyItemView(item: item, isSelected: isSelected)
                                }
                            )
                        }
                    }
                    .padding(.bottom)
                }
                Button("تم") {
                    isPresented = false
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.primary())
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.vertical)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(24)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct SpecialtyItemView: View {
    var item: Category
    var isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            if let imageUrl = item.image, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { img in
                    img.resizable()
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "questionmark.square")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
            }
            Text(item.title)
                .font(.body.bold())
                .foregroundColor(.primary)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.yellowF8B22A() : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.primary() : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    SpecialtySelectionPopup(
        isPresented: .constant(true),
        categories: [
            Category(id: "1", title: "مصمم", description: nil, image: nil, sub: nil),
            Category(id: "2", title: "مهندس برمجيات", description: nil, image: nil, sub: nil)
        ],
        selectedCategoryIds: .constant(["2"])
    )
}
