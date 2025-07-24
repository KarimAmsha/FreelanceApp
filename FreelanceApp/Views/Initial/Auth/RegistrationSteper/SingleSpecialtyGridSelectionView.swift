import SwiftUI

struct SingleSpecialtyGridSelectionView: View {
    @Binding var isPresented: Bool
    var categories: [Category]
    @Binding var selectedCategoryId: String?
    @Binding var selectedSubCategoryId: String?

    @State private var showSubcategory = false
    @State private var selectedCategory: Category?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.top, 8)

            Text("اختر التخصص الرئيسي")
                .font(.title3.bold())
                .foregroundColor(.primary)
                .padding(.bottom, 2)

            if categories.isEmpty {
                ProgressView("جارٍ تحميل التخصصات...")
                    .padding(.vertical)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(categories) { item in
                            categoryButton(for: item)
                        }
                    }
                    .padding(.bottom)
                }
            }

            Button("إغلاق") {
                isPresented = false
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.primary())
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.vertical)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(28)
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: $showSubcategory) {
            if let selected = selectedCategory, let subs = selected.sub {
                SubCategorySelectionView(
                    subCategories: subs,
                    selectedSubCategoryId: $selectedSubCategoryId,
                    isPresented: $showSubcategory,
                    parentDismiss: $isPresented
                )
            }
        }
    }

    @ViewBuilder
    private func categoryButton(for item: Category) -> some View {
        Button {
            selectedCategory = item
            selectedCategoryId = item.id
            if let subs = item.sub, !subs.isEmpty {
                showSubcategory = true
            } else {
                isPresented = false
            }
        } label: {
            VStack(spacing: 10) {
                if let urlStr = item.image, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { img in
                        img.resizable()
                    } placeholder: {
                        Color.gray.opacity(0.08)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    Image(systemName: "questionmark.square")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                }

                Text(item.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                if selectedCategoryId == item.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(selectedCategoryId == item.id ? Color.yellowF8B22A().opacity(0.15) : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedCategoryId == item.id ? Color.yellowF8B22A() : Color.clear, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
    }
}

#if DEBUG
struct SingleSpecialtyGridSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SingleSpecialtyGridSelectionView(
            isPresented: .constant(true),
            categories: [
                Category(id: "1", title: "مصمم", description: nil, image: nil, sub: nil),
                Category(id: "2", title: "مبرمج", description: nil, image: nil, sub: nil)
            ],
            selectedCategoryId: .constant("2"),
            selectedSubCategoryId: .constant(nil) // ✅ أضفت هذا السطر
        )
    }
}
#endif

struct SubCategorySelectionView: View {
    var subCategories: [SubCategory]
    @Binding var selectedSubCategoryId: String?
    @Binding var isPresented: Bool
    @Binding var parentDismiss: Bool

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("اختر التخصص الفرعي")
                .font(.title3.bold())
                .padding(.top)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(subCategories) { item in
                        subcategoryCard(item: item)
                    }
                }
            }

            Button("إغلاق") {
                isPresented = false
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.primary())
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.vertical)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(28)
        .environment(\.layoutDirection, .rightToLeft)
    }

    @ViewBuilder
    private func subcategoryCard(item: SubCategory) -> some View {
        Button {
            selectedSubCategoryId = item.id
            isPresented = false
            parentDismiss = false
        } label: {
            HStack {
                Text(item.title)
                    .customFont(weight: .medium, size: 14)
                    .foregroundColor(.primary)

                Spacer()

                if selectedSubCategoryId == item.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedSubCategoryId == item.id ? Color.yellowF8B22A() : Color.clear, lineWidth: 1.5)
            )
        }
    }
}
