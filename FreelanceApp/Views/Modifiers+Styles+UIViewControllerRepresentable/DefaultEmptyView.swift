//
//  DefaultEmptyView.swift
//  Fazaa
//
//  Created by Karim Amsha on 13.02.2024.
//

import SwiftUI

struct DefaultEmptyView: View {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "tray")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray.opacity(0.4))

            VStack(spacing: 8) {
                Text(title)
                    .customFont(weight: .bold, size: 18)
                    .foregroundColor(.primaryBlack())
                    .multilineTextAlignment(.center)

                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .customFont(weight: .regular, size: 14)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    Group {
        DefaultEmptyView(
            title: "لا توجد نتائج حالياً"
        )

        DefaultEmptyView(
            title: "لا توجد نتائج",
            subtitle: "يمكنك المحاولة لاحقًا أو تحديث الصفحة لرؤية البيانات الجديدة."
        )
    }
}
