import SwiftUI
import PopupView
import MapKit

struct EditProfileView: View {
    @EnvironmentObject var appRouter: AppRouter
    @State private var name = ""
    @State private var email = ""
    @State private var dateStr: String = ""
    @State private var userLocation: CLLocationCoordinate2D? = nil

    @StateObject private var viewModel = UserViewModel(errorHandling: ErrorHandling())
    @StateObject private var mediaPickerViewModel = MediaPickerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Profile Image Section
                    HStack(spacing: 16) {
                        profileImageView()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))

                        Spacer()

                        Button(action: {
                            // فتح اختيار صورة البروفايل
                            mediaPickerViewModel.isPresentingPickerFor = .profileImage
                        }) {
                            Text("اضغط لرفع صورة جديدة")
                                .font(.system(size: 14))
                                .foregroundColor(.primary())
                        }

                        Spacer()
                        
                        Button(action: {
                            // حذف صورة البروفايل
                            mediaPickerViewModel.removeMedia(for: .profileImage)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    .background(Color.primary().opacity(0.2))
                    .cornerRadius(12)

                    // MARK: - Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("اسم العرض")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        TextField("", text: $name)
                            .padding()
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.4))
                            )
                    }

                    // MARK: - Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("البريد الإلكتروني")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))

                        TextField("", text: $email)
                            .padding()
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.4))
                            )
                            .keyboardType(.emailAddress)
                    }

                    // MARK: - Save Button
                    Button(action: {
                        update()
                    }) {
                        Text("حفظ التغييرات")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundColor(.white)
                            .background(Color.primary())
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .background(Color.background())
        .onAppear {
            getUserData()
            if let location = LocationManager.shared.userLocation {
                userLocation = location
            }
        }
        // ImageVideoPicker: للصور فقط في هذه الشاشة
        .sheet(item: $mediaPickerViewModel.isPresentingPickerFor) { type in
            ImageVideoPicker(
                sourceType: mediaPickerViewModel.sourceType,
                mediaTypes: ["public.image"]
            ) { img, url in
                mediaPickerViewModel.didSelectImage(img)
            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.black)
                    }
                    Text("اسم وصورة العرض")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }
            }
        }
    }

    // MARK: - Profile Image View
    @ViewBuilder
    func profileImageView() -> some View {
        if let selectedImage = mediaPickerViewModel.getImage(for: .profileImage) {
            Image(uiImage: selectedImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            let imageURL = viewModel.user?.image?.toURL()
            AsyncImageView(
                width: 90,
                height: 90,
                cornerRadius: 45,
                imageURL: imageURL,
                placeholder: Image(systemName: "person.fill"),
                contentMode: .fill
            )
        }
    }

    // MARK: - Update Profile
    private func update() {
        let image = mediaPickerViewModel.getImage(for: .profileImage)
        let userId = viewModel.user?.id ?? viewModel.user?.phone_number ?? "unknown"

        if let image = image {
            // ارفع الصورة باستخدام FirestoreService
            FirestoreService.shared.uploadImageWithThumbnail(
                image: image,
                id: userId,
                imageName: "profile"
            ) { url, success in
                if success, let url = url {
                    // أكمل تعديل البروفايل مع رابط الصورة الجديدة
                    self.performProfileUpdate(imageURL: url)
                } else {
                    showMessage(message: "فشل رفع الصورة. حاول مرة أخرى.")
                }
            }
        } else {
            // لم يغير الصورة، أرسل الرابط القديم أو nil
            let oldUrl = viewModel.user?.image
            self.performProfileUpdate(imageURL: oldUrl)
        }
    }

    private func performProfileUpdate(imageURL: String?) {
        let params: [String: Any] = [
            "full_name": name,
            "email": email,
            "lat": userLocation?.latitude ?? 0.0,
            "lng": userLocation?.longitude ?? 0.0,
            "image": imageURL ?? ""
        ]
        // دالتك المعتادة في ViewModel
        viewModel.updateUserDataWithImage(imageData: nil, additionalParams: params) { message in
            showMessage(message: message)
        }
    }

    private func getUserData() {
        viewModel.fetchUserData {
            name = viewModel.user?.full_name ?? ""
            email = viewModel.user?.email ?? ""
            dateStr = viewModel.user?.formattedDOB ?? ""
        }
    }

    private func showMessage(message: String) {
        let alertModel = AlertModel(
            icon: "",
            title: "",
            message: message,
            hasItem: false,
            item: nil,
            okTitle: "تم",
            cancelTitle: "رجوع",
            hidesIcon: true,
            hidesCancel: true
        ) {
            appRouter.dismissPopup()
            appRouter.navigateBack()
        } onCancelAction: {
            appRouter.dismissPopup()
        }

        appRouter.togglePopup(.alert(alertModel))
    }
}

#Preview {
    EditProfileView()
        .environmentObject(UserSettings())
        .environmentObject(AppState())
}
