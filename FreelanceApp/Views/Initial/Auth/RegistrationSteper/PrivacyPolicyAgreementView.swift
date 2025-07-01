import SwiftUI

struct PrivacyPolicyAgreementView: View {
    @Binding var showSheet: Bool
    var onAgree: () -> Void

    @State private var contentHeight: CGFloat = 0
    @StateObject private var initialViewModel = InitialViewModel(errorHandling: ErrorHandling())

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("الموافقة على سياسة الاستخدام والخصوصية")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Spacer()
                Button(action: { showSheet = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.top)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let item = initialViewModel.constantsItems?.first(where: { $0.constantType == .privacy }) {
                        HTMLView(html: item.Content ?? "", contentHeight: $contentHeight)
                            .frame(height: contentHeight)
                    } else if initialViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("لا يوجد سياسة خصوصية متاحة حالياً")
                            .foregroundColor(.gray)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.vertical)
            }

            PrimaryActionButton(title: "أوافق على سياسة الاستخدام والخصوصية") {
                onAgree()
                showSheet = false
            }
            .padding(.vertical)
        }
        .padding()
        .background(Color.white)
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            initialViewModel.fetchConstantsItems()
        }
    }
}

#Preview {
    PrivacyPolicyAgreementView(showSheet: .constant(true), onAgree: {})
}
