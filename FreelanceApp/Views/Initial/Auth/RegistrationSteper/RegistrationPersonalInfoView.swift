import SwiftUI

struct RegistrationPersonalInfoView: View {
    @State var presentSheet = false
    @ObservedObject var viewModel: RegistrationViewModel
    @State private var showDatePicker = false
    @State private var selectedDate: Date? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            RegistrationStepHeader(
                title: "المعلومات الشخصية",
                subtitle: "يرجى تعبئة جميع الحقول بدقة لضمان استكمال التسجيل."
            )

            // رقم الجوال
            VStack(alignment: .leading, spacing: 6) {
                Text("رقم الهاتف")
                    .customFont(weight: .medium, size: 14)
                    .foregroundColor(.black151515())
                HStack {
                    Text(viewModel.getCompletePhoneNumber())
                        .customFont(weight: .medium, size: 14)
                        .foregroundColor(.black151515())
                    Spacer()
                }
                .padding()
                .background(Color.backgroundFEFEFE())
                .cornerRadius(10)
            }

            // الاسم الكامل
            AppTextField(
                title: "الاسم الكامل",
                text: $viewModel.full_name,
                placeholder: "أدخل اسمك الكامل"
            )

            // البريد الإلكتروني
            AppTextField(
                title: "البريد الإلكتروني",
                text: $viewModel.email,
                placeholder: "example@email.com",
                keyboardType: .emailAddress
            )

            // رقم السجل التجاري أو تاريخ الميلاد حسب نوع الحساب
            if viewModel.selectedRole == .company {
                AppTextField(
                    title: "رقم السجل التجاري",
                    text: $viewModel.reg_no,
                    placeholder: "أدخل رقم السجل التجاري"
                )
            }

            if viewModel.selectedRole == .personal {
                BirthdatePickerField(
                    title: "تاريخ الميلاد",
                    date: $selectedDate,
                    isPresented: $showDatePicker
                )
            }

            // نبذة عنك
            AppTextEditor(
                title: "نبذة عنك",
                text: $viewModel.bio,
                placeholder: "اكتب نبذة قصيرة عنك..."
            )

            // الموقع (إذا متاح)
            if !viewModel.address.isEmpty {
                Text("📍 \(viewModel.address)")
                    .customFont(weight: .regular, size: 13)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color.background())
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker(
                    "اختر تاريخ الميلاد",
                    selection: Binding(
                        get: { selectedDate ?? Date() },
                        set: {
                            selectedDate = $0
                            viewModel.dob = formatDateForBackend($0)
                            showDatePicker = false
                        }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ar"))

                Button("تم") {
                    showDatePicker = false
                }
                .padding()
            }
            .presentationDetents([.height(300)])
        }
        .onAppear {
            requestLocation()
        }
    }

    private func requestLocation() {
        LocationManager.shared.requestLocationOnce()
        LocationManager.shared.onLocationUpdate = { location in
            viewModel.lat = location.coordinate.latitude
            viewModel.lng = location.coordinate.longitude
            viewModel.address = LocationManager.shared.address
        }
    }

    func formatDateForBackend(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

#Preview {
    RegistrationPersonalInfoView(viewModel: RegistrationViewModel())
}

struct AppTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .customFont(weight: .medium, size: 14)
                .foregroundColor(.black151515())

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(Color.backgroundFEFEFE())
                .cornerRadius(10)
        }
    }
}

struct AppTextEditor: View {
    var title: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .customFont(weight: .medium, size: 14)
                .foregroundColor(.black151515())

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .customFont(weight: .regular, size: 13)
                }

                TextEditor(text: $text)
                    .padding(8)
                    .frame(height: 100)
                    .background(Color.backgroundFEFEFE())
                    .cornerRadius(10)
            }
        }
    }
}

import SwiftUI

struct BirthdatePickerField: View {
    var title: String
    @Binding var date: Date?
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .customFont(weight: .medium, size: 14)
                .foregroundColor(.black151515())

            Button {
                isPresented = true
            } label: {
                HStack {
                    Text(date != nil ? formattedDate : "اختر تاريخ الميلاد")
                        .foregroundColor(date != nil ? .black : .gray)
                        .customFont(weight: .regular, size: 15)
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.backgroundFEFEFE())
                .cornerRadius(10)
            }
        }
    }

    private var formattedDate: String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy" // ⬅️ للعرض فقط
        formatter.locale = Locale(identifier: "ar")
        return formatter.string(from: date)
    }
}
