import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = NotificationsViewModel()

    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if viewModel.state.isLoading && viewModel.notificationsItems.isEmpty {
                        LoadingView()
                    } else if viewModel.notificationsItems.isEmpty {
                        DefaultEmptyView(title: LocalizedStringKey.noDataFound)
                    } else {
                        ForEach(viewModel.notificationsItems, id: \.self) { item in
                            NotificationRowView(notification: item)
                                .onTapGesture {
                                    if item.notificationType == .orders {
//                                        appRouter.navigate(to: .orderDetails(item.bodyParams ?? ""))
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteNotification(item)
                                    } label: {
                                        Label(LocalizedStringKey.delete, systemImage: "trash")
                                    }
                                }
                        }

                        if viewModel.shouldLoadMoreData {
                            Color.clear
                                .frame(height: 1)
                                .onAppear {
                                    loadMore()
                                }
                        }

                        if viewModel.state.isLoading && !viewModel.notificationsItems.isEmpty {
                            LoadingView().padding(.vertical, 12)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image("ic_back")
                    }

                    Text(LocalizedStringKey.notifications)
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .bindLoadingState(viewModel.state, to: appRouter)
        .onAppear {
            loadData()
        }
    }

    private func loadData() {
        viewModel.resetPagination()
        viewModel.fetchNotificationsItems(page: 0)
    }

    private func loadMore() {
        viewModel.loadMoreNotifications()
    }

    private func deleteNotification(_ notification: NotificationItem) {
        appRouter.showAlert(
            title: "هل تريد حذف هذا الإشعار؟",
            message: nil,
            okTitle: "حذف",
            cancelTitle: "رجوع",
            onOK: {
                viewModel.deleteNotification(id: notification.id ?? "") { message in
                    appRouter.show(.success, message: message)
                    loadData()
                }
            }
        )
    }
}
