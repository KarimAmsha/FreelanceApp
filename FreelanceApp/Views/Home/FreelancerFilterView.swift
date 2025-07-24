import SwiftUI

struct FreelancerFilterView: View {
    @Binding var filters: FreelancerFilter
    var onApply: (() -> Void)?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // المسافة
                    Text("المسافة (كم)")
                        .font(.headline)

                    CustomSliderView(
                        value: Binding(
                            get: { Double(filters.distanceTo) },
                            set: { filters.distanceTo = Int($0) }
                        ),
                        range: 0...1000, step: 10
                    )
                    Text("حتى \(filters.distanceTo) كم")
                        .foregroundColor(.gray)

                    Divider()

                    // التقييم
                    Text("التقييم")
                        .font(.headline)

                    HStack {
                        CustomStepperView(label: "من", value: $filters.rateFrom, range: 0...filters.rateTo)
                        Spacer()
                        CustomStepperView(label: "إلى", value: $filters.rateTo, range: filters.rateFrom...5)
                    }

                    Divider()

                    // الأرباح
                    Text("الأرباح")
                        .font(.headline)

                    HStack {
                        CustomStepperView(label: "من", value: $filters.profitFrom, range: 0...filters.profitTo)
                        Spacer()
                        CustomStepperView(label: "إلى", value: $filters.profitTo, range: filters.profitFrom...10)
                    }

                    Divider()

                    // الكلمة المفتاحية
                    Text("كلمة مفتاحية")
                        .font(.headline)

                    TextField("اسم المستقل", text: $filters.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: {
                        onApply?()
                    }) {
                        Text("تطبيق الفلتر")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 24)
                }
                .padding()
            }
            .navigationTitle("فلترة البحث")
        }
    }
}

struct CustomSliderView: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double

    var body: some View {
        SwiftUI.Slider(value: $value, in: range, step: step)
            .accentColor(.blue)
    }
}

struct CustomStepperView: View {
    var label: String
    @Binding var value: Int
    var range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text("\(label) \(value)")
            Spacer()
            SwiftUI.Stepper("", value: $value, in: range)
                .labelsHidden()
        }
    }
}
