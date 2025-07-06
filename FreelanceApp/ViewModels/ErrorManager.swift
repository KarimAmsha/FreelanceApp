//
//  ErrorManager.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 6.07.2025.
//

import SwiftUI
import Combine

enum AppMessageType {
    case error
    case success
    case warning
    case info
}

class ErrorManager: ObservableObject {
    @Published var message: String = ""
    @Published var show: Bool = false
    @Published var type: AppMessageType = .error

    func show(_ message: String, type: AppMessageType = .error) {
        self.message = message
        self.type = type
        self.show = true
    }

    func hide() {
        self.message = ""
        self.show = false
    }
}
