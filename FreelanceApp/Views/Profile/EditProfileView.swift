import SwiftUI
import MapKit
import PopupView

struct EditProfileView: View {
    @EnvironmentObject var appRouter: AppRouter
    @State private var name = ""
    @State private var email = ""
    @State private var userLocation: CLLocationCoordinate2D? = nil

    @StateObject private var viewModel = UserViewModel()
    @StateObject private var mediaPickerViewModel = MediaPickerViewModel()

    @State private var showCustomSheet = false
    @State private var uploadingProfile = false
    @State private var profileUploadProgress: Double? = nil
    @State private var showDatePicker = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    EditProfileCardView(
                        mediaPickerViewModel: mediaPickerViewModel,
                        showCustomSheet: $showCustomSheet,
                        imageUrl: viewModel.user?.image
                    )
                    
                    ProfileInputFields(
                        name: $viewModel.name,
                        email: $viewModel.email,
                        selectedDate: $viewModel.dobDate,
                        showDatePicker: $showDatePicker,
                        viewModel: viewModel
                    )

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
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        withAnimation { appRouter.navigateBack() }
                    } label: {
                        Image(systemName: "arrow.backward")
                            .resizable()
                            .frame(width: 20, height: 15)
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color.white.clipShape(Circle()))
                    }

                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey.editProfile)
                            .customFont(weight: .bold, size: 20)
                        Text(LocalizedStringKey.editProfileHint)
                            .customFont(weight: .regular, size: 10)
                    }
                    .foregroundColor(Color.black222020())
                }
            }
        }
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
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker(
                    "اختر تاريخ الميلاد",
                    selection: Binding(
                        get: { viewModel.dobDate ?? Date() },
                        set: {
                            viewModel.dobDate = $0
                            showDatePicker = false
                        }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ar"))

                Button("تم") {
                    showDatePicker = false
                }
                .padding()
            }
            .presentationDetents([.height(300)])
        }
    }

    private func update() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty, trimmedName.count >= 3 else {
            showMessage(message: "الرجاء إدخال اسم لا يقل عن 3 أحرف")
            return
        }

        guard !trimmedEmail.isEmpty else {
            showMessage(message: "يرجى إدخال البريد الإلكتروني")
            return
        }

        guard isValidEmail(trimmedEmail) else {
            showMessage(message: "البريد الإلكتروني غير صالح")
            return
        }

        if viewModel.selectedRole == .personal && viewModel.dobDate == nil {
            showMessage(message: "يرجى اختيار تاريخ الميلاد")
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
            email: viewModel.email.trimmingCharacters(in: .whitespaces),
            full_name: viewModel.name.trimmingCharacters(in: .whitespaces),
            lat: userLocation?.latitude ?? user.lat ?? 0.0,
            lng: userLocation?.longitude ?? user.lng ?? 0.0,
            reg_no: user.reg_no,
            address: user.address,
            country: user.country,
            city: user.city,
            dob: viewModel.dobDate?.formatted("yyyy-MM-dd") ?? user.dob,
            category: user.category,
            subcategory: user.subcategory,
            work: user.work,
            bio: user.bio,
            image: imageURL ?? user.image,
            id_image: user.id_image
        )

        viewModel.updateUserData(body: body) { message in
            appRouter.show(.success, message: "تم تحديث الملف الشخصي بنجاح")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                appRouter.navigateBack()
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func getUserData() {
        viewModel.fetchUser {
            name = viewModel.user?.full_name ?? ""
            email = viewModel.user?.email ?? ""
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
