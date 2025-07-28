//
//  CustomPhotoSourceSheet.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 28.07.2025.
//

import SwiftUI

struct CustomPhotoSourceSheet: View {
    let pickCamera: () -> Void
    let pickGallery: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            Capsule()
                .frame(width: 36, height: 5)
                .foregroundColor(.gray.opacity(0.3))
                .padding(.top, 10)

            Text("تغيير صورة الملف الشخصي")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            HStack(spacing: 36) {
                // الكاميرا
                OptionButton(icon: "camera", label: "الكاميرا", action: pickCamera)

                // المعرض
                OptionButton(icon: "photo", label: "المعرض", action: pickGallery)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            Color(.systemBackground)
                .opacity(0.98)
                .blur(radius: 0.7)
        )
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
    }

    // MARK: - Subview
    @ViewBuilder
    func OptionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}
