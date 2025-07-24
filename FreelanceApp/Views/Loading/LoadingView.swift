//
//  LoadingView.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView(LocalizedStringKey.loading)
            .progressViewStyle(CircularProgressViewStyle(tint: .primary()))
            .background(Color.clear)
            .padding()
    }
}

struct LinearProgressView: View {
    var label: String
    var progress: Double
    var color: Color
    
    init(_ label: String, progress: Double, color: Color) {
        self.label = label
        self.progress = progress
        self.color = color
    }
    
    var body: some View {
        ProgressView(label, value: progress)
            .progressViewStyle(LinearProgressViewStyle(tint: color))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}

struct GlobalLoadingView: View {
    var title: String = "جارٍ التحميل..."

    var body: some View {
        ZStack {
            // طبقة غامقة نصف شفافة
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primary()))
                    .scaleEffect(1.8)

                Text(title)
                    .customFont(weight: .medium, size: 16)
                    .foregroundColor(.primary())
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            )
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: UUID())
    }
}
