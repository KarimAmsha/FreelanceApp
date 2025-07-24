//
//  AddressBookView.swift
//  Fazaa
//
//  Created by Karim Amsha on 29.02.2024.
//

import SwiftUI

struct AddressBookView: View {
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var viewModel = UserViewModel()

    var body: some View {
        VStack {
            GeometryReader { geometry in
                VStack(alignment: .center) {
                    if viewModel.state.isLoading && (viewModel.addressBook?.isEmpty ?? true) {
                        LoadingView()
                    }

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            if let addressBook = viewModel.addressBook, addressBook.isEmpty {
                                DefaultEmptyView(title: LocalizedStringKey.noDataFound)
                            } else {
                                List {
                                    ForEach(viewModel.addressBook ?? [], id: \.id) { item in
                                        AddressRowView(item: item)
                                            .onTapGesture {
                                                appRouter.navigate(to: .addressBookDetails(item))
                                            }
                                            .swipeActions {
                                                Button {
                                                    showAlertDeleteMessage(item: item)
                                                } label: {
                                                    Label(LocalizedStringKey.delete, systemImage: "trash")
                                                }
                                                .tint(.red)
                                            }
                                            .listRowSeparator(.hidden)
                                    }
                                }
                                .listStyle(.plain)
                                .listRowInsets(EdgeInsets())
                                .scrollIndicators(.hidden)
                                .environment(\.layoutDirection, .leftToRight)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geometry.size.height)
                        .background(Color.white.cornerRadius(8))
                    }
                }
                .padding(.horizontal, 24)
                .edgesIgnoringSafeArea(.bottom)
            }

            Spacer()

            HStack {
                Spacer()
                Button(action: {
                    appRouter.navigate(to: .addAddressBook)
                }) {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.primary())
                        .clipShape(Circle())
                }
                .padding(.bottom, 24)
                .padding(.trailing, 24)
            }
        }
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .bindLoadingState(viewModel.state, to: appRouter)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        withAnimation {
                            appRouter.navigateBack()
                        }
                    } label: {
                        Image(systemName: "arrow.backward")
                            .resizable()
                            .frame(width: 20, height: 15)
                            .foregroundColor(.black)
                            .padding(.vertical, 13)
                            .padding(.horizontal, 8)
                            .background(Color.white.cornerRadius(8))
                    }

                    Text(LocalizedStringKey.addressBook)
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.black141F1F())
                }
            }
        }
        .onAppear {
            getAddressList()
        }
    }
}

#Preview {
    AddressBookView()
        .environmentObject(AppRouter())
}

extension AddressBookView {
    private func getAddressList() {
        viewModel.fetchAddresses()
    }

    private func showAlertDeleteMessage(item: AddressItem) {
        appRouter.showAlert(
            title: "هل تريد حذف هذا العنوان؟",
            message: nil,
            okTitle: "حذف",
            cancelTitle: "رجوع",
            onOK: {
                deleteAddress(item: item)
            }
        )
    }

    private func deleteAddress(item: AddressItem) {
        viewModel.deleteAddress(id: item.id ?? "") { message in
            appRouter.show(.success, message: message)
            getAddressList()
        }
    }
}
