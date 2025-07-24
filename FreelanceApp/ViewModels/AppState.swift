//
//  AppState.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI

// أنواع التوست المركزي
enum ToastType: Equatable {
    case none
    case success(title: String, message: String)
    case error(title: String, message: String)
}

class AppState: ObservableObject {
    // الحالة الرئيسية للتبويب
    @Published var currentTab: MainTab = .home

    // التوست المركزي (نجاح أو خطأ)
    @Published var toast: ToastType = .none

    // عرض نافذة تسجيل الخروج (لو تحتاج)
    @Published var showLogoutView: Bool = false

    // ---- دوال التوست ----
    func showSuccessToast(_ message: String, title: String = "") {
        toast = .success(title: title, message: message)
    }

    func showErrorToast(_ message: String, title: String = "") {
        toast = .error(title: title, message: message)
    }

    func clearToast() {
        toast = .none
    }
}
