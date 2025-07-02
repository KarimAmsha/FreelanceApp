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

    @State private var showPhotoSourceSheet = false

    // لتحسين bottom sheet التجريبي بدل الـActionSheet
    @State private var showCustomSheet = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // MARK: - Profile Card
                    profileCardView()

                    // MARK: - Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("اسم العرض")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("اسم العرض", text: $name)
                            .padding(.horizontal)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.22), lineWidth: 1))
                    }

                    // MARK: - Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("البريد الإلكتروني")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("البريد الإلكتروني", text: $email)
                            .keyboardType(.emailAddress)
                            .padding(.horizontal)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.22), lineWidth: 1))
                    }

                    // MARK: - Save Button
                    Button(action: {
                        update()
                    }) {
                        Text("حفظ التغييرات")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.primary)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: Color.primary.opacity(0.12), radius: 6, x: 0, y: 3)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .background(Color("BgGray").ignoresSafeArea())
        .onAppear {
            if name.isEmpty || email.isEmpty {
                getUserData()
                if let location = LocationManager.shared.userLocation {
                    userLocation = location
                }
            }
        }
        // BottomSheet حديث بدل ActionSheet
        .sheet(isPresented: $showCustomSheet) {
            CustomPhotoSourceSheet(
                pickCamera: {
                    showCustomSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        mediaPickerViewModel.pickPhoto(for: .profileImage, fromCamera: true)
                    }
                },
                pickGallery: {
                    showCustomSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        mediaPickerViewModel.pickPhoto(for: .profileImage, fromCamera: false)
                    }
                }
            )
            .presentationDetents([.height(180)])
            .presentationDragIndicator(.visible)
        }
        // Sheet للبيكر الأساسي
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
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    Text("تعديل الملف الشخصي")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
    }

    // MARK: - Profile Card View
    @ViewBuilder
    func profileCardView() -> some View {
        HStack(alignment: .center, spacing: 16) {
            // صورة البروفايل (يمين)
            profileImageView()
                .frame(width: 78, height: 78)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .background(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 84, height: 84)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
                .padding(.trailing, 2)
            
            // نص زر اختيار صورة (وسط)
            Button(action: {
                showCustomSheet = true
            }) {
                Text("اضغط لرفع صورة جديدة")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.black121212())
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 2)
            
            Spacer()
            
            // زر حذف الصورة (يسار)
            if mediaPickerViewModel.getImage(for: .profileImage) != nil {
                Button(action: {
                    mediaPickerViewModel.removeMedia(for: .profileImage)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Circle())
                }
                .padding(.leading, 2)
            } else {
                Spacer().frame(width: 44)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(
            LinearGradient(gradient: Gradient(colors: [
                Color.white, Color(.systemGray6)
            ]), startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.03), radius: 9, x: 0, y: 3)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Profile Image View
    @ViewBuilder
    func profileImageView() -> some View {
        if let selectedImage = mediaPickerViewModel.getImage(for: .profileImage) {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
        } else if let url = viewModel.user?.image?.toURL() {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.gray)
            }
        } else {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFill()
                .foregroundColor(.gray)
        }
    }

    // MARK: - Update Profile
    private func update() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showMessage(message: "يرجى إدخال الاسم")
            return
        }
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            showMessage(message: "يرجى إدخال البريد الإلكتروني")
            return
        }

        let image = mediaPickerViewModel.getImage(for: .profileImage)
        let userId = viewModel.user?.id ?? viewModel.user?.phone_number ?? "unknown"

        if let image = image {
            FirestoreService.shared.uploadImageWithThumbnail(
                image: image,
                id: userId,
                imageName: "profile"
            ) { url, success in
                if success, let url = url {
                    self.performProfileUpdate(imageURL: url)
                } else {
                    showMessage(message: "فشل رفع الصورة. حاول مرة أخرى.")
                }
            }
        } else {
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

// MARK: - Custom Bottom Sheet
// MARK: - Custom Bottom Sheet
struct CustomPhotoSourceSheet: View {
    var pickCamera: () -> Void
    var pickGallery: () -> Void
    
    var body: some View {
        VStack(spacing: 26) {
            Capsule()
                .frame(width: 32, height: 5)
                .foregroundColor(Color.primary.opacity(0.10))
                .padding(.top, 10)
            
            Text("تغيير صورة الملف الشخصي")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.primary)
                .padding(.bottom, 12)
            
            HStack(spacing: 30) {
                // زر الكاميرا
                Button(action: pickCamera) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.primary().opacity(0.13))
                                .frame(width: 60, height: 60)
                            Image(systemName: "camera")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(Color.primary())
                        }
                        Text("الكاميرا")
                            .font(.system(size: 13))
                            .foregroundColor(Color.primary)
                            .padding(.top, 4)
                    }
                }
                // زر المعرض
                Button(action: pickGallery) {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(Color.primary().opacity(0.13))
                                .frame(width: 60, height: 60)
                            Image(systemName: "photo")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(Color.primary())
                        }
                        Text("المعرض")
                            .font(.system(size: 13))
                            .foregroundColor(Color.primary)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(.bottom, 4)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            Color(.systemBackground)
                .opacity(0.98)
                .blur(radius: 0.8)
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: -2)
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AppRouter())
        .environmentObject(AppState())
}
