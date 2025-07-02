//
//  OTPVerificationView.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 2.07.2025.
//

import SwiftUI

struct OTPVerificationView: View {
    @State private var code: [String] = Array(repeating: "", count: 4)
    @FocusState private var focusedIndex: Int?
    @State private var timer: Int = 59
    @State private var canResend: Bool = false

    let phone: String

    var body: some View {
        VStack(spacing: 26) {
            // العنوان
            HStack {
                Spacer()
                Text("تأكيد رقم الهاتف الجديد")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Button(action: {
                    // dismiss
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            // وصف وبيان الرقم
            VStack(spacing: 4) {
                Text("تم إرسال رمز التفعيل إلى رقم هاتفك")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                Text(phone)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }

            // مربعات إدخال OTP
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { i in
                    TextField("", text: $code[i])
                        .focused($focusedIndex, equals: i)
                        .keyboardType(.numberPad)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(code[i].isEmpty ? Color.gray.opacity(0.30) : Color.green, lineWidth: 2)
                                .background(Color(.systemBackground))
                        )
                        .onChange(of: code[i]) { value in
                            if value.count > 1 {
                                code[i] = String(value.suffix(1))
                            }
                            if !value.isEmpty && i < 3 {
                                focusedIndex = i+1
                            }
                        }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 6)

            // عداد وزر إعادة إرسال
            HStack(spacing: 16) {
                Button(action: {
                    if canResend {
                        resendCode()
                    }
                }) {
                    Text("طلب رمز جديد")
                        .font(.system(size: 15))
                        .foregroundColor(canResend ? Color.green : Color.gray.opacity(0.7))
                }
                Spacer()
                Text("\(timer) ث | لم يصلك رمزًا؟")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)

            // زر تأكيد الرقم
            Button(action: {
                // تحقق من الكود
            }) {
                Text("تأكيد رقم الهاتف الجديد")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 50)
            .background(Color.green)
            .cornerRadius(12)
            .padding(.horizontal, 6)
            .padding(.bottom, 16)

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 24)
        .background(Color(.systemBackground))
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            startTimer()
        }
    }

    // عداد الثواني
    func startTimer() {
        timer = 59
        canResend = false
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if timer > 0 {
                timer -= 1
            }
            if timer == 0 {
                canResend = true
                t.invalidate()
            }
        }
    }
    // إعادة إرسال الرمز
    func resendCode() {
        // send code...
        startTimer()
    }
}
