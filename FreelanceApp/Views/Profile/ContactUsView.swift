import SwiftUI
import PopupView

struct ContactUsView: View {
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var viewModel = ContactUsViewModel()

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var description = ""

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        inputField(title: "الاسم الكامل", text: $name)
                        inputField(title: "البريد الإلكتروني", text: $email, keyboard: .emailAddress)
                        inputField(title: "رقم الهاتف", text: $phone, keyboard: .phonePad)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("محتوى الرسالة")
                                .customFont(weight: .regular, size: 12)
                                .foregroundColor(.black1F1F1F())
                            TextEditor(text: $description)
                                .customFont(weight: .regular, size: 14)
                                .foregroundColor(.black)
                                .frame(height: 200)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .roundedBackground(cornerRadius: 12, strokeColor: .primary(), lineWidth: 1)
                        }

                        Button("إرسال") {
                            sendComplaint()
                        }
                        .buttonStyle(PrimaryButton(
                            fontSize: 16,
                            fontWeight: .bold,
                            background: .primary(),
                            foreground: .white,
                            height: 48,
                            radius: 12
                        ))
                        .disabled(viewModel.isLoading)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                }
                .padding(24)
            }
            .navigationBarBackButtonHidden()
            .background(Color.background())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Button {
                            withAnimation { appRouter.navigateBack() }
                        } label: {
                            Image(systemName: "arrow.backward")
                                .resizable()
                                .frame(width: 20, height: 15)
                                .foregroundColor(.black)
                                .padding(12)
                                .background(Color.white.clipShape(Circle()))
                        }

                        VStack(alignment: .leading) {
                            Text("تواصل معنا")
                                .customFont(weight: .bold, size: 20)
                            Text("نسعد بخدمتك دائمًا")
                                .customFont(weight: .regular, size: 10)
                        }
                        .foregroundColor(Color.black222020())
                    }
                }
            }
            .bindLoadingState(viewModel.state, to: appRouter)
            .onAppear {
                viewModel.fetchContactItems()
            }
        }
    }

    // MARK: - Field Builder
    @ViewBuilder
    func inputField(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .customFont(weight: .regular, size: 12)
                .foregroundColor(.black1F1F1F())
            CustomTextField(text: text, placeholder: title, textColor: .black4E5556(), placeholderColor: .grayA4ACAD())
                .keyboardType(keyboard)
                .roundedBackground(cornerRadius: 12, strokeColor: .primary(), lineWidth: 1)
                .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Send Logic
    func sendComplaint() {
        let request = AddComplaintRequest(
            full_name: name,
            email: email,
            phone_number: phone,
            details: description
        )

        viewModel.addComplain(body: request) { message in
            showSuccessMessage(message)
        }
    }

    func showSuccessMessage(_ message: String) {
        appRouter.showAlert(
            title: "خطأ",
            message: message,
            okTitle: "تم",
            cancelTitle: "رجوع",
            onOK: {},
            onCancel: {}
        )
    }
}

#Preview {
    ContactUsView()
        .environmentObject(UserSettings())
        .environmentObject(AppRouter())
}
