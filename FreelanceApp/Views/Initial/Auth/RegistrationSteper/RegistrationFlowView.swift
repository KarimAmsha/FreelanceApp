import SwiftUI
import FirebaseMessaging

enum RegistrationStep: Int {
    case role, personalInfo, workInfo, identity
}

struct RegistrationFlowView: View {
    @State private var step: RegistrationStep = .role
    @State private var showSpecialtyPopup = false
    @State private var showPrivacySheet = false
    @State private var showSuccessPopup = false
    @State private var agreedToPrivacy = false

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var regViewModel: RegistrationViewModel
    @StateObject var mediaVM = MediaPickerViewModel()
    @EnvironmentObject var appRouter: AppRouter

    var steps: [RegistrationStep] {
        guard let role = regViewModel.selectedRole else {
            return [.role] // default initial step
        }

        switch role {
        case .personal:
            return [.role, .personalInfo, .workInfo, .identity]
        case .company:
            return [.role, .personalInfo, .identity]
        case .none:
            return [.role]
        }
    }

    @ViewBuilder
    var currentStepView: some View {
        switch step {
        case .role:
            if regViewModel.isCompleteProfile {
                CompletedProfileView(selectedRole: regViewModel.selectedRole)
            } else {
                RegistrationRoleView(selectedRole: $regViewModel.selectedRole)
            }
        case .personalInfo:
            RegistrationPersonalInfoView(viewModel: regViewModel)
        case .workInfo:
            RegistrationWorkInfoView(viewModel: regViewModel, showSpecialtyPopup: $showSpecialtyPopup)
        case .identity:
            RegistrationIdentityView(mediaVM: mediaVM, viewModel: regViewModel)
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if steps.count > 1 {
                    StepTabsView(currentStep: step, steps: steps)
                        .padding(.top)
                }

                Spacer(minLength: 10)

                currentStepView

                Spacer(minLength: 10)

                HStack(spacing: 12) {
                    if step != .role {
                        SecondaryActionButton(title: "رجوع") {
                            goToPrevious()
                        }
                    }
                    PrimaryActionButton(title: getButtonTitle(), isLoading: regViewModel.isLoading) {
                        handleButtonAction()
                    }
                }
                .padding(.bottom)
            }
            .padding(.horizontal)
            .background(Color.background())
            .environment(\.layoutDirection, .rightToLeft)

            if showSuccessPopup {
                SuccessSubmissionView(isPresented: $showSuccessPopup)
                    .environmentObject(appState)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .bindLoadingState(regViewModel.state, to: appRouter)
        .sheet(isPresented: $showPrivacySheet) {
            PrivacyPolicyAgreementView(showSheet: $showPrivacySheet) {
                agreedToPrivacy = true
                showSuccessPopup = true
            }
        }
        .onAppear {
            regViewModel.restoreIfNeeded(using: appRouter)
        }
    }

    private func getButtonTitle() -> String {
        if step == steps.last {
            return "إتمام الطلب"
        } else {
            return "التالي"
        }
    }

    private func handleButtonAction() {
        regViewModel.resetState()

        switch step {
        case .role:
            if regViewModel.selectedRole != nil {
                goToNext()
            } else {
                regViewModel.state = .failure(error: "يرجى اختيار نوع الحساب")
            }

        case .personalInfo:
            if let error = regViewModel.getMissingProfileField(skipImageValidation: true, skipCategory: true) {
                regViewModel.failLoading(error: error)
                return
            }
            goToNext()

        case .workInfo:
            if let error = regViewModel.getMissingProfileField(skipImageValidation: true) {
                regViewModel.failLoading(error: error)
                return
            }
            goToNext()

        case .identity:
            if let error = regViewModel.getMissingProfileField() {
                regViewModel.failLoading(error: error)
                return
            }
            regViewModel.updateProfile {
                if regViewModel.isCompleteProfile {
                    appState.currentTab = .home
                } else {
                    goToNext()
                }
            }
        }
    }

    private func goToNext() {
        if let idx = steps.firstIndex(of: step), idx + 1 < steps.count {
            step = steps[idx + 1]
        }
    }

    private func goToPrevious() {
        if let idx = steps.firstIndex(of: step), idx > 0 {
            step = steps[idx - 1]
        }
    }
}

struct CompletedProfileView: View {
    let selectedRole: UserRole?
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: selectedRole == .company ? "person.2.fill" : "person.fill")
                .font(.system(size: 48))
                .foregroundColor(.primary())
            Text(selectedRole == .company ? "نوع حسابك: مقدم خدمة" : "نوع حسابك: صاحب مشاريع")
                .customFont(weight: .bold, size: 18)
                .foregroundColor(.primary())
            Text("لا يمكن تغيير نوع الحساب بعد إكمال التسجيل.")
                .customFont(weight: .regular, size: 13)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

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
