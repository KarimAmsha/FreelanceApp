//
//  SnackbarErrorView.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 6.07.2025.
//

import SwiftUI

struct SnackbarErrorView: View {
    var message: String
    var type: AppMessageType
    var onClose: (() -> Void)? = nil

    var iconName: String {
        switch type {
        case .error: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.seal.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    var bgColor: Color {
        switch type {
        case .error: return .red.opacity(0.98)
        case .success: return .green.opacity(0.95)
        case .warning: return .orange.opacity(0.97)
        case .info: return .blue.opacity(0.95)
        }
    }

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.title2)
                Text(message)
                    .foregroundColor(.white)
                    .font(.body)
                    .lineLimit(3)
                Spacer()
                Button(action: {
                    onClose?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.title3)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(bgColor)
                    .shadow(radius: 8, y: 6)
            )
            .padding(.horizontal, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .zIndex(99)
    }
}
