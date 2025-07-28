//
//  BirthdatePickerFieldForEdit.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 28.07.2025.
//

import SwiftUI

struct BirthdatePickerFieldForEdit: View {
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
                    Text(dateText)
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

    private var dateText: String {
        guard let date else { return "اختر تاريخ الميلاد" }
        return DateFormatter.englishDisplay.string(from: date)
    }
}
