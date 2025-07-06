import SwiftUI

import SwiftUI

struct AdvancedProgressView: View {
    var progress: Double = 0.5       // 0.0 - 1.0
    var icon: String = "photo"       // SF Symbol
    var color: Color = .blue
    var bgColor: Color = .gray.opacity(0.15)
    var size: CGFloat = 64
    var showPercent: Bool = true
    var text: String? = nil
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // خلفية دائرية خفيفة
                Circle()
                    .stroke(lineWidth: size * 0.11)
                    .foregroundColor(bgColor)
                    .frame(width: size, height: size)
                
                // تقدم فعلي
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
                    .foregroundColor(color)
                    .rotationEffect(.degrees(-90))
                    .frame(width: size, height: size)
                    .animation(.easeInOut, value: progress)
                
                // الأيقونة + النسبة
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: size * 0.33, weight: .bold))
                        .foregroundColor(color)
                    if showPercent {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: size * 0.24, weight: .semibold))
                            .foregroundColor(color)
                    }
                }
            }
            if let text = text {
                Text(text)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 30) {
        AdvancedProgressView(progress: 0.4, icon: "person.crop.circle.fill", color: .blue, text: "رفع صورة البروفايل")
        AdvancedProgressView(progress: 1, icon: "checkmark.circle.fill", color: .green, showPercent: false, text: "تم الرفع بنجاح!")
        AdvancedProgressView(progress: 0.78, icon: "doc.richtext", color: .orange, text: "جاري رفع الملف...")
    }
    .padding()
}
