import SwiftUI

struct AppMessage: Identifiable, Equatable {
    let id = UUID()
    let type: AppMessageType
    let title: String?
    let message: String
}

enum AppMessageType: String {
    case error, success, warning, info

    var iconName: String {
        switch self {
        case .error: return "xmark.octagon.fill"
        case .success: return "checkmark.seal.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .error: return Color.red.opacity(0.95)
        case .success: return Color.green.opacity(0.95)
        case .warning: return Color.orange.opacity(0.95)
        case .info: return Color.blue.opacity(0.95)
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .error: return "خطأ"
        case .success: return "نجاح"
        case .warning: return "تحذير"
        case .info: return "معلومة"
        }
    }
}

struct AppMessageBannerView: View {
    var title: String
    var message: String
    var type: AppMessageType
    var onClose: (() -> Void)? = nil

    var body: some View {
        VStack {
            Spacer()

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: type.iconName)
                    .font(.title3)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .customFont(weight: .bold, size: 16)
                        .foregroundColor(.white)

                    Text(message)
                        .customFont(weight: .regular, size: 14)
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.system(size: 18))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(type.backgroundColor)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: message)
        }
        .zIndex(100)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.accessibilityLabel): \(title). \(message)")
    }
}
