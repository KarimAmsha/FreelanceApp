import SwiftUI

struct TabBarIcon: View {
    @EnvironmentObject var appState: AppState
    let assignedPage: MainTab
    let width, height: CGFloat
    let iconName, tabName: String
    var count: Int? = nil
    var isNotified: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(appState.currentTab == assignedPage ? .primary() : .gray6C7278())
                    .frame(width: width, height: height)
                if isNotified && (count ?? 0) > 0 {
                    Text("\(count ?? 0)")
                        .customFont(weight: .medium, size: 13)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 12, y: -8)
                }
            }
            Text(tabName)
                .customFont(weight: appState.currentTab == assignedPage ? .bold : .regular, size: 12)
                .foregroundColor(appState.currentTab == assignedPage ? .primary() : .primaryBlack())
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            appState.currentTab = assignedPage
        }
    }
}

#Preview {
    TabBarIcon(
        assignedPage: .home,
        width: 38,
        height: 38,
        iconName: "house",
        tabName: "الرئيسية",
        count: 5,
        isNotified: true
    )
    .environmentObject(AppState())
}
