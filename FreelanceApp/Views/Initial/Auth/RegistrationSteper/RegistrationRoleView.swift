import SwiftUI

enum UserRole: String {
    case company
    case personal
    case none

    var roleTitle: String? {
        switch self {
        case .personal:
            return "مقدم خدمة"
        case .company:
            return "صاحب مشاريع"
        case .none:
            return nil
        }
    }
}

struct RegistrationRoleView: View {
    @Binding var selectedRole: UserRole?

    var body: some View {
        VStack(spacing: 24) {
            RegistrationStepHeader(
                title: "مقدمة خدمة أم عميل؟",
                subtitle: "هل تقدم خدمات معينة أم تحتاج إلى توظيف محترفين؟"
            )

            VStack(spacing: 16) {
                RoleCardView(
                    icon: "person.fill",
                    title: "مقدم خدمة",
                    description: "ستكون قادرًا على عرض أعمالك وتلقي العروض من العملاء عبر المنصة.",
                    selected: selectedRole == .personal
                ) { selectedRole = .personal }

                RoleCardView(
                    icon: "building.2.fill",
                    title: "صاحب مشاريع",
                    description: "سنساعدك في اختيار أفضل مقدمين الخدمات والحصول على خدمة مميزة",
                    selected: selectedRole == .company
                ) { selectedRole = .company }
            }
        }
        .padding()
        .background(Color.background())
        .environment(\..layoutDirection, .rightToLeft)
    }
}

#Preview {
    RegistrationRoleView(selectedRole: .constant(nil))
}

// MARK: - Reusable Components

struct RegistrationStepHeader: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: "C58B32"))
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RoleCardView: View {
    var icon: String
    var title: String
    var description: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 32))
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .foregroundColor(selected ? .white : .black)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(selected ? Color.yellowF8B22A() : Color.yellowFFF3D9())
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.black.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct PrimaryActionButton: View {
    var title: String
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            if !isLoading {
                action()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary())
                    .frame(height: 50)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .disabled(isLoading)
    }
}

struct SecondaryActionButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
        }
    }
}

struct MessageAlertView: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(8)
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut, value: message)
    }
}
