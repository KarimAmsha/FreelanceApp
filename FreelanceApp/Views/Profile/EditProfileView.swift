import SwiftUI
import PopupView
import MapKit

struct EditProfileView: View {
    @EnvironmentObject var appRouter: AppRouter
    @State private var name = ""
    @State private var email = ""
    @State private var dateStr: String = ""
    @State private var userLocation: CLLocationCoordinate2D? = nil

    @StateObject private var viewModel = UserViewModel()
    @StateObject private var mediaPickerViewModel = MediaPickerViewModel()

    @State private var showCustomSheet = false
    @State private var uploadingProfile = false
    @State private var profileUploadProgress: Double? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    profileCardView()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("اسم العرض")
                            .customFont(weight: .regular, size: 13)
                            .foregroundColor(.gray)
                        TextField("اسم العرض", text: $name)
                            .padding(.horizontal)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.22), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("البريد الإلكتروني")
                            .customFont(weight: .regular, size: 13)
                            .foregroundColor(.gray)
                        TextField("البريد الإلكتروني", text: $email)
                            .keyboardType(.emailAddress)
                            .padding(.horizontal)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.22), lineWidth: 1))
                    }

                    if uploadingProfile {
                        AdvancedProgressView(
                            progress: profileUploadProgress ?? 0.01,
                            icon: "person.crop.circle.fill",
                            color: .primary(),
                            bgColor: .gray.opacity(0.17),
                            size: 64,
                            text: "جاري رفع الصورة"
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                    }

                    Button(action: update) {
                        Text("حفظ التغييرات")
                            .customFont(weight: .medium, size: 16)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.primary())
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
        .background(Color.background().ignoresSafeArea())
        .bindLoadingState(viewModel.state, to: appRouter)
        .onAppear {
            if name.isEmpty || email.isEmpty {
                getUserData()
                userLocation = LocationManager.shared.userCoordinate
            }
        }
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
        .sheet(item: $mediaPickerViewModel.isPresentingPickerFor) { type in
            ImageVideoPicker(
                sourceType: mediaPickerViewModel.sourceType,
                mediaTypes: ["public.image"]
            ) { img, _ in
                mediaPickerViewModel.didSelectImage(img)
            }
        }
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
                        .customFont(weight: .bold, size: 18)
                        .foregroundColor(.primary)
                }
            }
        }
    }

    @ViewBuilder
    private func profileCardView() -> some View {
        HStack(alignment: .center, spacing: 16) {
            profileImageView()
                .frame(width: 78, height: 78)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .background(Circle().fill(Color.white).frame(width: 84, height: 84))
                .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
                .padding(.trailing, 2)

            Button(action: { showCustomSheet = true }) {
                Text("اضغط لرفع صورة جديدة")
                    .customFont(weight: .medium, size: 15)
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
            LinearGradient(gradient: Gradient(colors: [Color.white, Color(.systemGray6)]), startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.03), radius: 9, x: 0, y: 3)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .environment(\.layoutDirection, .rightToLeft)
    }

    @ViewBuilder
    private func profileImageView() -> some View {
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
        if let image = image {
            uploadingProfile = true
            profileUploadProgress = 0

            NetworkManager.shared.uploadImage(
                image: image,
                progressHandler: { progress in
                    profileUploadProgress = progress
                }
            ) { result in
                uploadingProfile = false
                profileUploadProgress = nil
                switch result {
                case .success(let url):
                    performProfileUpdate(imageURL: url)
                case .failure(let error):
                    showMessage(message: "فشل رفع الصورة. حاول مرة أخرى.\n\(error.localizedDescription)")
                }
            }
        } else {
            performProfileUpdate(imageURL: viewModel.user?.image)
        }
    }

    private func performProfileUpdate(imageURL: String?) {
        guard let user = viewModel.user else {
            showMessage(message: "تعذر تحميل بيانات المستخدم.")
            return
        }

        let body = UpdateUserRequest(
            email: email,
            full_name: name,
            lat: userLocation?.latitude ?? user.lat ?? 0.0,
            lng: userLocation?.longitude ?? user.lng ?? 0.0,
            reg_no: user.reg_no,
            address: user.address,
            country: user.country,
            city: user.city,
            dob: user.dob,
            category: user.category,
            subcategory: user.subcategory,
            work: user.work,
            bio: user.bio,
            image: imageURL ?? user.image,
            id_image: user.id_image
        )

        viewModel.updateUserData(body: body) { message in
            showMessage(message: message)
        }
    }

    private func getUserData() {
        viewModel.fetchUser {
            name = viewModel.user?.full_name ?? ""
            email = viewModel.user?.email ?? ""
            dateStr = viewModel.user?.formattedDOB ?? ""
        }
    }

    private func showMessage(message: String) {
        appRouter.showAlert(
            title: "تنبيه",
            message: message,
            okTitle: "تم",
            cancelTitle: "رجوع",
            onOK: {
                appRouter.navigateBack()
            },
            onCancel: {
                appRouter.dismissAlert()
            }
        )
    }
}

#Preview {
    EditProfileView()
        .environmentObject(AppRouter())
        .environmentObject(AppState())
}

struct CustomPhotoSourceSheet: View {
    let pickCamera: () -> Void
    let pickGallery: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            Capsule()
                .frame(width: 36, height: 5)
                .foregroundColor(.gray.opacity(0.3))
                .padding(.top, 10)

            Text("تغيير صورة الملف الشخصي")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            HStack(spacing: 36) {
                // الكاميرا
                OptionButton(icon: "camera", label: "الكاميرا", action: pickCamera)

                // المعرض
                OptionButton(icon: "photo", label: "المعرض", action: pickGallery)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            Color(.systemBackground)
                .opacity(0.98)
                .blur(radius: 0.7)
        )
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -2)
    }

    // MARK: - Subview
    @ViewBuilder
    func OptionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}
