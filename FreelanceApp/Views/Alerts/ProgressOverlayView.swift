//
//  ProgressOverlayView.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 6.07.2025.
//

import SwiftUI

struct ProgressOverlayView: View {
    var message: String = "جاري التحميل..."
    var systemImage: String = "arrow.2.circlepath"
    var showBlur: Bool = true
    var progress: Double? = nil // نسبة التحميل (0.0 إلى 1.0) أو nil لو عادي

    var body: some View {
        ZStack {
            if showBlur {
                Color.black.opacity(0.16)
                    .ignoresSafeArea()
                    .blur(radius: 2)
            }
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 58, height: 58)
                        .shadow(color: .gray.opacity(0.16), radius: 16, x: 0, y: 8)
                    if let progress = progress {
                        ProgressView(value: progress)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.4)
                            .frame(width: 36, height: 36)
                        Text("\(Int(progress * 100))%")
                            .font(.footnote).bold()
                            .foregroundColor(.blue)
                            .offset(y: 32)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.4)
                            .frame(width: 36, height: 36)
                    }
                }
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(message)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(radius: 12)
        }
        .transition(.opacity.combined(with: .scale))
        .zIndex(100)
    }
}
