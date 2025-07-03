//
//  PersonalInfoView.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI
import PopupView
import MapKit
import FirebaseStorage

struct PersonalInfoView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appRouter: AppRouter
    @State private var name = ""
    @State private var email = ""
    @StateObject private var viewModel = UserViewModel(errorHandling: ErrorHandling())
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
        span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
    )
    @State private var description: String = LocalizedStringKey.specificText
    @State var placeholderString = LocalizedStringKey.specificText
    @State private var isFloatingPickerPresented = false
    @StateObject var mediaPickerViewModel = MediaPickerViewModel()
    @FocusState private var keyIsFocused: Bool
    @State private var isShowingDatePicker = false
    @State private var dateStr: String = ""
    @State private var date: Date = Date()

    var body: some View {
        GeometryReader { geometry in
//            VStack(alignment: .leading, spacing: 0) {
//                ScrollView(.vertical, showsIndicators: false) {
//                    VStack(alignment: .leading, spacing: 12) {
//                        VStack(alignment: .center, spacing: 8) {
//                            profileImageView()
//                                .shadow(color: .primary().opacity(0.16), radius: 2.5, x: 0, y: 5)
//                            Button {
//                                isFloatingPickerPresented.toggle()
//                            } label: {
//                                Text(LocalizedStringKey.uploadProfilePicture)
//                            }
//                            .buttonStyle(PrimaryButton(fontSize: 12, fontWeight: .medium, background: .primaryLightActive(), foreground: .primary(), height: 44, radius: 12))
//                            .disabled(viewModel.isLoading)
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding(24)
//                        .background(Color.primaryLightHover().cornerRadius(4))
//                        .padding(6)
//                        .background(Color.primaryLight().cornerRadius(4))
//
//                        Text(LocalizedStringKey.personalInformation)
//                            .customFont(weight: .bold, size: 16)
//                            .foregroundColor(.primaryBlack())
//
//                        VStack(alignment: .leading) {
//                            Text(LocalizedStringKey.fullName)
//                                .customFont(weight: .medium, size: 12)
//
//                            TextField(LocalizedStringKey.fullName, text: $name)
//                                .placeholder(when: name.isEmpty) {
//                                    Text(LocalizedStringKey.fullName)
//                                        .foregroundColor(.gray999999())
//                                }
//                                .focused($keyIsFocused)
//                                .customFont(weight: .regular, size: 14)
//                                .accentColor(.primary())
//                                .padding(.horizontal, 16)
//                                .padding(.vertical, 18)
//                                .roundedBackground(cornerRadius: 12, strokeColor: .primaryBlack(), lineWidth: 1)
//                        }
//                        .foregroundColor(.black222020())
//
//                        VStack(alignment: .leading) {
//                            Text(LocalizedStringKey.email)
//                                .customFont(weight: .medium, size: 12)
//
//                            TextField(LocalizedStringKey.email, text: $email)
//                                .placeholder(when: email.isEmpty) {
//                                    Text(LocalizedStringKey.email)
//                                        .foregroundColor(.gray999999())
//                                }
//                                .focused($keyIsFocused)
//                                .customFont(weight: .regular, size: 14)
//                                .keyboardType(.emailAddress)
//                                .accentColor(.primary())
//                                .padding(.horizontal, 16)
//                                .padding(.vertical, 18)
//                                .roundedBackground(cornerRadius: 12, strokeColor: .primaryBlack(), lineWidth: 1)
//                        }
//                        .foregroundColor(.black222020())
//
//                        Spacer()
//
//                        if let uploadProgress = viewModel.uploadProgress {
//                            LinearProgressView(LocalizedStringKey.loading, progress: uploadProgress, color: .primary())
//                        }
//
//                        Button {
//                            update()
//                        } label: {
//                            Text(LocalizedStringKey.saveChanges)
//                        }
//                        .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
//                        .disabled(viewModel.isLoading)
//                    }
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .frame(minHeight: geometry.size.height)
//                }
//            }
        }
        .dismissKeyboardOnTap()
//        .fullScreenCover(isPresented: $mediaPickerViewModel.isPresentingImagePicker, content: {
//            ImagePicker(sourceType: mediaPickerViewModel.sourceType) { img, _ in
//                mediaPickerViewModel.didSelectImage(img)
//            }
//        })
//        .popup(isPresented: $isFloatingPickerPresented) {
//            FloatingPickerView(
//                isPresented: $isFloatingPickerPresented,
//                onChoosePhoto: { mediaPickerViewModel.choosePhoto() },
//                onTakePhoto: { mediaPickerViewModel.takePhoto() }
//            )
//        } customize: {
//            $0
//                .type(.toast)
//                .position(.bottom)
//                .animation(.spring())
//                .closeOnTapOutside(false)
//                .closeOnTap(false)
//                .backgroundColor(.black.opacity(0.5))
//        }
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Image("ic_gift")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey.myProfile)
                            .customFont(weight: .bold, size: 20)
                        Text(LocalizedStringKey.profileHint)
                            .customFont(weight: .regular, size: 12)
                    }
                    .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .onAppear {
            getUserData()
            if let userLocation = LocationManager.shared.userCoordinate {
                self.userLocation = userLocation
            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .popup(isPresented: $isShowingDatePicker) {
            let dateModel = DateTimeModel(pickerMode: .date) { date in
                self.date = date
                dateStr = date.toString(format: "yyyy-MM-dd")
                isShowingDatePicker = false
            } onCancelAction: {
                isShowingDatePicker = false
            }
            DateTimePicker(model: dateModel)
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .animation(.spring())
                .closeOnTapOutside(true)
                .closeOnTap(false)
                .backgroundColor(Color.black.opacity(0.80))
                .isOpaque(true)
                .useKeyboardSafeArea(true)
        }
    }
}

#Preview {
    PersonalInfoView()
        .environmentObject(UserSettings())
        .environmentObject(AppState())
}

extension PersonalInfoView {
    private func getUserData() {
        viewModel.fetchUserData {
            name = viewModel.user?.full_name ?? ""
            email = viewModel.user?.email ?? ""
            dateStr = viewModel.user?.formattedDOB ?? ""
        }
    }
    
    private func update() {
//        let userId = viewModel.user?.id ?? viewModel.user?.phone_number ?? "unknown"
//        let paramsBase: [String: Any] = [
//            "email": email,
//            "full_name": name,
//            "lat": userLocation?.latitude ?? 0.0,
//            "lng": userLocation?.longitude ?? 0.0,
//            "address": "",
//            "dob": dateStr,
//        ]
//        if let image = mediaPickerViewModel.selectedImage {
//            FirestoreService.shared.uploadImageWithThumbnail(
//                image: image,
//                id: userId,
//                imageName: "profile"
//            ) { url, success in
//                if success, let url = url {
//                    var params = paramsBase
//                    params["image"] = url
//                    viewModel.updateUserDataWithImage(imageData: nil, additionalParams: params) { _ in
//                        settings.loggedIn = true
//                    }
//                } else {
//                    viewModel.errorMessage = "فشل رفع الصورة. حاول مرة أخرى."
//                }
//            }
//        } else {
//            var params = paramsBase
//            if let oldImage = viewModel.user?.image {
//                params["image"] = oldImage
//            }
//            viewModel.updateUserDataWithImage(imageData: nil, additionalParams: params) { _ in
//                settings.loggedIn = true
//            }
//        }
    }
}

//extension PersonalInfoView {
//    @ViewBuilder
//    func profileImageView() -> some View {
//        if let selectedImage = mediaPickerViewModel.selectedImage {
//            Image(uiImage: selectedImage)
//                .resizable()
//                .frame(width: 115, height: 115)
//                .cornerRadius(8)
//        } else {
//            let imageURL = viewModel.user?.image?.toURL()
//            AsyncImageView(
//                width: 115,
//                height: 115,
//                cornerRadius: 8,
//                imageURL: imageURL,
//                placeholder: Image(systemName: "photo.circle"),
//                contentMode: .fill
//            )
//        }
//    }
//}
