//
//  RegistrationPersonalInfoView.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 6.05.2025.
//

import SwiftUI

struct RegistrationPersonalInfoView: View {
    @State var presentSheet = false
    @ObservedObject var viewModel: RegistrationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            RegistrationStepHeader(
                title: "المعلومات الشخصية",
                subtitle: "يرجى تعبئة البيانات الشخصية بدقة لضمان إنشاء الحساب."
            )

//            HStack(spacing: 100) {
//                GenderOption(title: "ذكر", selected: $viewModel.gender, value: "male")
//                GenderOption(title: "أنثى", selected: $viewModel.gender, value: "female")
//            }

            TextField("الاسم الكامل", text: $viewModel.full_name)
                .padding()
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))

            MobileView(mobile: $viewModel.phone_number, presentSheet: $presentSheet)

            Spacer()
        }
        .padding()
        .background(Color.background())
        .environment(\.layoutDirection, .rightToLeft)
    }
}

#Preview {
    RegistrationPersonalInfoView(viewModel: RegistrationViewModel(errorHandling: ErrorHandling()))
}

struct GenderOption: View {
    var title: String
    @Binding var selected: String
    var value: String

    var body: some View {
        Button(action: {
            selected = value
        }) {
            HStack {
                Circle()
                    .fill(selected == value ? Color.yellowF8B22A() : Color.yellowFFF3D9())
                    .frame(width: 20, height: 20)
                Text(title)
                    .customFont(weight: .medium, size: 16)
                    .foregroundColor(.black151515())
            }
        }
    }
}
