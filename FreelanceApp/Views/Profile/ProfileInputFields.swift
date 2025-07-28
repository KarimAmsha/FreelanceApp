
// ProfileInputFields.swift
import SwiftUI

struct ProfileInputFields: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var selectedDate: Date?
    @Binding var showDatePicker: Bool
    @ObservedObject var viewModel: UserViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("اسم العرض")
                    .customFont(weight: .regular, size: 13)
                    .foregroundColor(.gray)
                TextField("اسم العرض", text: $name)
                    .padding(.horizontal)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.22), lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("البريد الإلكتروني")
                    .customFont(weight: .regular, size: 13)
                    .foregroundColor(.gray)
                TextField("البريد الإلكتروني", text: $email)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.22), lineWidth: 1))
            }

            if viewModel.selectedRole == .company {
                AppTextField(
                    title: "رقم السجل التجاري",
                    text: $viewModel.reg_no,
                    placeholder: "أدخل رقم السجل التجاري"
                )
            }

            if viewModel.selectedRole == .personal {
                BirthdatePickerFieldForEdit(
                    title: "تاريخ الميلاد",
                    date: $viewModel.dobDate,
                    isPresented: $showDatePicker
                )
            }

            AppTextEditor(
                title: "نبذة عنك",
                text: $viewModel.bio,
                placeholder: "اكتب نبذة قصيرة عنك..."
            )
        }
    }
}
