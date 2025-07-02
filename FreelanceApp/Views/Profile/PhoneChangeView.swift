import SwiftUI

struct PhoneChangeView: View {
    @StateObject var vm = PhoneChangeViewModel(errorHandling: ErrorHandling())
    @EnvironmentObject var appRouter: AppRouter

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(alignment: .leading) {
                if vm.step == .enterOldPhone {
                    VStack(alignment: .leading, spacing: 18) {
                        MobileView(
                            mobile: $vm.oldPhone,
                            presentSheet: .constant(false),
                            countryPatternPalceholder: "5# ### ####"
                        )
                        Text("سنقوم بارسال رمز تاكيد مكون من 4 خانات لتاكيد رقم الهاتف الحالي.")
                            .customFont(weight: .regular, size: 12)
                            .foregroundColor(.gray)

                        Button("إرسال رمز التحقق") {
                            vm.requestOldOtp()
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.primary())
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 20)
                        if let err = vm.errorMessage {
                            Text(err)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                        Spacer()
                    }
                    .padding()
                }

                else if vm.step == .enterNewPhone {
                    VStack(spacing: 18) {
                        MobileView(
                            mobile: $vm.newPhone,
                            presentSheet: .constant(false),
                            countryPatternPalceholder: "5# ### ####"
                        )
                        Button("تعديل الرقم وإرسال كود") {
                            vm.updateNewPhone()
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color.primary())
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 10)
                        if let err = vm.errorMessage {
                            Text(err)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
                        Spacer()
                    }
                    .padding()
                }

                else if vm.step == .success {
                    VStack(spacing: 32) {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 62, height: 62)
                            .foregroundColor(.green)
                        Text("تم تغيير رقم الهاتف بنجاح")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
            }

            // بوب أب تحقق للهاتف القديم
            .sheet(isPresented: $vm.showOldOtpPopup) {
                OtpPopupView(
                    phone: vm.oldPhone,
                    otp: $vm.oldOtp,
                    isLoading: vm.isLoading,
                    timer: vm.timer,
                    canResend: vm.canResend,
                    error: vm.errorMessage,
                    onSubmit: { vm.verifyOldOtp { _ in } },
                    onResend: { vm.resendOldOtp() }
                )
                .presentationDetents([.medium])
                .environment(\.layoutDirection, .rightToLeft)
            }

            // بوب أب تحقق للهاتف الجديد
            .sheet(isPresented: $vm.showNewOtpPopup) {
                OtpPopupView(
                    phone: vm.newPhone,
                    otp: $vm.newOtp,
                    isLoading: vm.isLoading,
                    timer: vm.timer,
                    canResend: vm.canResend,
                    error: vm.errorMessage,
                    onSubmit: { vm.verifyNewOtp { _ in } },
                    onResend: { vm.resendNewOtp() }
                )
                .presentationDetents([.medium])
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    Text(vm.step == .enterOldPhone ? "تغيير رقم الهاتف" : "ادخال رقم الهاتف الجديد")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

#Preview {
    PhoneChangeView()
        .environmentObject(AppRouter())
}

struct OtpPopupView: View {
    let phone: String
    @Binding var otp: String
    let isLoading: Bool
    let timer: Int
    let canResend: Bool
    let error: String?
    let onSubmit: () -> Void
    let onResend: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .frame(width: 34, height: 5)
                .foregroundColor(.gray.opacity(0.22))
                .padding(.top, 8)
            Text("أدخل رمز التحقق")
                .font(.system(size: 18, weight: .bold))
            Text("تم إرسال رمز من 4 خانات إلى: \(phone)")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            OtpFormFieldView(combinedPins: $otp)
                .padding(.vertical, 6)
                .environment(\.layoutDirection, .leftToRight)
            HStack(spacing: 14) {
                Button(action: {
                    if canResend { onResend() }
                }) {
                    Text("طلب رمز جديد")
                        .font(.system(size: 15))
                        .foregroundColor(canResend ? Color.primaryGreen() : Color.gray.opacity(0.7))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 7)
                        .background(Color.gray.opacity(0.13))
                        .cornerRadius(8)
                }
                .disabled(!canResend)
                Spacer()
                Text("\(timer) ث")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 2)
            if let err = error {
                Text(err)
                    .foregroundColor(.red)
                    .font(.system(size: 13))
            }
            Spacer()
            Button(action: onSubmit) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("تأكيد")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.primary())
                        .cornerRadius(12)
                }
            }
            .padding(.vertical, 6)
        }
        .padding()
    }
}
