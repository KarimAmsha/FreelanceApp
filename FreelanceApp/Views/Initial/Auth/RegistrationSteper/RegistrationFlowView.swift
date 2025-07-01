import SwiftUI

// Enum steps for registration
enum RegistrationStep: Int, CaseIterable {
    case role, personalInfo, confirmPhone, workInfo, identity
}

struct RegistrationFlowView: View {
    @State private var step: RegistrationStep = .role
    @State private var showSpecialtyPopup = false
    @State private var showPrivacySheet = false
    @State private var showSuccessPopup = false
    @State private var agreedToPrivacy = false
    
    @EnvironmentObject var appState: AppState
    @StateObject private var regViewModel = RegistrationViewModel(errorHandling: ErrorHandling())
    @StateObject var mediaVM = MediaPickerViewModel()
    
    // الخطوات بناءً على الدور
    var steps: [RegistrationStep] {
        if regViewModel.selectedRole == .personal {
            return [.role, .personalInfo, .confirmPhone]
        } else {
            return [.role, .personalInfo, .confirmPhone, .workInfo, .identity]
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                StepTabsView(currentStep: step, steps: steps)
                    .padding(.top)
                
                Spacer(minLength: 10)
                
                ZStack {
                    switch step {
                    case .role:
                        RegistrationRoleView(selectedRole: $regViewModel.selectedRole)
                    case .personalInfo:
                        RegistrationPersonalInfoView(viewModel: regViewModel)
                    case .workInfo:
                        RegistrationWorkInfoView(viewModel: regViewModel, showSpecialtyPopup: $showSpecialtyPopup)
                    case .identity:
                        RegistrationIdentityView(mediaVM: mediaVM, viewModel: regViewModel)
                    case .confirmPhone:
                        ConfirmPhoneView(regViewModel: regViewModel, onComplete: {
                            showSuccessPopup = true
                        })
                    }
                }
                .animation(.easeInOut, value: step)
                .transition(.slide)
                
                Spacer(minLength: 10)
                
                // الأزرار في الأسفل
                HStack(spacing: 12) {
                    if step != .role {
                        SecondaryActionButton(title: "رجوع") {
                            goToPrevious()
                        }
                    }
                    PrimaryActionButton(title: getButtonTitle()) {
                        handleButtonAction()
                    }
                }
                .padding(.bottom)
            }
            .padding(.horizontal)
            .background(Color.background())
            .environment(\.layoutDirection, .rightToLeft)
            .overlay(
                MessageAlertObserverView(
                    message: $regViewModel.errorMessage,
                    alertType: .constant(.error)
                )
            )
            // نافذة النجاح
            .popup(isPresented: $showSuccessPopup) {
                SuccessSubmissionView(isPresented: $showSuccessPopup)
                    .environmentObject(appState)
            } customize: {
                $0
                    .type(.default)
                    .position(.bottom)
                    .closeOnTapOutside(false)
                    .backgroundColor(Color.black.opacity(0.4))
                    .useKeyboardSafeArea(true)
            }
        }
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyPolicyAgreementView(showSheet: $showPrivacySheet) {
                agreedToPrivacy = true
                showSuccessPopup = true
            }
        }
    }
    
    // --- فالديشن & انتقال للخطوة التالية ---
    private func goToNext() {
        regViewModel.errorMessage = nil

        switch step {
        case .personalInfo:
            if regViewModel.full_name.trimmingCharacters(in: .whitespaces).isEmpty ||
                regViewModel.phone_number.trimmingCharacters(in: .whitespaces).isEmpty {
                regViewModel.errorMessage = "يرجى تعبئة جميع الحقول المطلوبة"
                return
            }
            // هنا أضف signup بدل الانتقال المباشر
            regViewModel.signup { result in
                switch result {
                case .success:
                    // انتقل للخطوة التالية (عادة confirmPhone)
                    if let currentIndex = steps.firstIndex(of: step),
                       currentIndex + 1 < steps.count {
                        step = steps[currentIndex + 1]
                    }
                case .failure(let error):
                    regViewModel.errorMessage = error.localizedDescription
                }
            }
        case .workInfo:
            if regViewModel.selectedCategoryIds.isEmpty {
                regViewModel.errorMessage = "يرجى اختيار التخصص"
                return
            }
            fallthrough
        case .identity:
            if step == .identity && (regViewModel.imageURL == nil || regViewModel.idImageURL == nil) {
                regViewModel.errorMessage = "يرجى رفع صورة شخصية وصورة هوية"
                return
            }
            fallthrough
        default:
            // انتقل للخطوة التالية إذا لم يكن هناك خطأ
            if let currentIndex = steps.firstIndex(of: step),
               currentIndex + 1 < steps.count {
                step = steps[currentIndex + 1]
            }
        }
    }

    private func goToPrevious() {
        regViewModel.errorMessage = nil
        if let currentIndex = steps.firstIndex(of: step),
           currentIndex > 0 {
            step = steps[currentIndex - 1]
        }
    }
    
    private func getButtonTitle() -> String {
        if step == .confirmPhone {
            return regViewModel.isPhoneVerified ? "التالي" : "تحقق من رقم الهاتف"
        } else if step == steps.last {
            return "إتمام الطلب"
        } else {
            return "التالي"
        }
    }
    
    private func handleButtonAction() {
        // الخطوة الأخيرة: إرسال البيانات النهائية بعد الموافقة على سياسة الخصوصية
        if step == steps.last {
            if agreedToPrivacy {
                regViewModel.updateProfile { result in
                    switch result {
                    case .success:
                        showSuccessPopup = true
                    case .failure(let error):
                        regViewModel.errorMessage = error.localizedDescription
                    }
                }
            } else {
                showPrivacySheet = true
            }
        }
        // خطوة تأكيد الهاتف
        else if step == .confirmPhone {
            // تحقق من أن المستخدم أدخل كود صالح (مثلاً 4 أو 6 أرقام)
            guard regViewModel.otp.trimmingCharacters(in: .whitespacesAndNewlines).count >= 4 else {
                regViewModel.errorMessage = "يرجى إدخال رمز التفعيل الصحيح"
                return
            }
            // لم يتم التحقق بعد
            if !regViewModel.isPhoneVerified {
                regViewModel.verifyPhone(verifyCode: regViewModel.otp) { result in
                    switch result {
                    case .success:
                        regViewModel.isPhoneVerified = true
                        goToNext()
                    case .failure(let error):
                        regViewModel.errorMessage = error.localizedDescription
                    }
                }
            } else {
                // إذا كان الرقم مُتحقق منه مسبقًا انتقل للخطوة التالية
                goToNext()
            }
        }
        // أي خطوة أخرى (انتقال عادي مع الفالديشن من goToNext)
        else {
            goToNext()
        }
    }
}

// --- شريط الخطوات ---
struct StepTabsView: View {
    var currentStep: RegistrationStep
    var steps: [RegistrationStep]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(steps, id: \.self) { step in
                Rectangle()
                    .fill(color(for: step))
                    .frame(height: 4)
            }
        }
    }

    private func color(for step: RegistrationStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            return Color(hex: "F8B22A")
        } else if step == currentStep {
            return Color.primary()
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

#Preview {
    RegistrationFlowView()
}

