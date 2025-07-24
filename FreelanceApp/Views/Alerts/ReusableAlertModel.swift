//
//  ReusableAlertModel.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 24.07.2025.
//

// MARK: - Reusable Alert View

import SwiftUI

// MARK: - Alert Type
enum AlertType {
    case `default`
    case destructive
    case logout
    case warning

    var confirmColor: Color {
        switch self {
        case .default:
            return .accentColor
        case .destructive:
            return .red
        case .logout:
            return .orange
        case .warning:
            return .yellow
        }
    }
}

// MARK: - Reusable Model
struct ReusableAlertModel: Identifiable {
    let id = UUID()

    let title: String
    let message: String?
    let okTitle: String
    let cancelTitle: String
    let type: AlertType
    let onOK: () -> Void
    let onCancel: (() -> Void)?

    init(
        title: String,
        message: String? = nil,
        okTitle: String = "موافق",
        cancelTitle: String = "رجوع",
        type: AlertType = .default,
        onOK: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.okTitle = okTitle
        self.cancelTitle = cancelTitle
        self.type = type
        self.onOK = onOK
        self.onCancel = onCancel
    }
}

struct AppCustomAlertView: View {
    let alert: ReusableAlertModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(alert.title)
                .customFont(weight: .bold, size: 18)
                .foregroundColor(.primaryBlack())
                .multilineTextAlignment(.center)

            if let message = alert.message {
                Text(message)
                    .customFont(weight: .regular, size: 15)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button(action: {
                    alert.onOK()
                    isPresented = false
                }) {
                    Text(alert.okTitle)
                        .customFont(weight: .medium, size: 16)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(alert.type.confirmColor)
                        .cornerRadius(12)
                }

                Button(action: {
                    alert.onCancel?()
                    isPresented = false
                }) {
                    Text(alert.cancelTitle)
                        .customFont(weight: .medium, size: 16)
                        .foregroundColor(.primaryBlack())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(24)
        .padding(.horizontal, 36)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func appAlert(using router: AppRouter) -> some View {
        self.overlay(
            Group {
                if let alert = router.alertModel {
                    ZStack {
                        Color.black.opacity(0.45)
                            .ignoresSafeArea()
                            .onTapGesture {
                                router.dismissAlert()
                            }

                        AppCustomAlertView(alert: alert, isPresented: Binding(
                            get: { router.alertModel != nil },
                            set: { newVal in if !newVal { router.dismissAlert() } }
                        ))
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: router.alertModel != nil)
                }
            }
        )
    }
}
