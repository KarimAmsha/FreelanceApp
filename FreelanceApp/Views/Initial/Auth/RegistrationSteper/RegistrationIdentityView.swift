import SwiftUI

struct RegistrationIdentityView: View {
    @ObservedObject var mediaVM: MediaPickerViewModel
    @ObservedObject var viewModel: RegistrationViewModel
    @State private var uploadingProfile = false
    @State private var uploadingID = false
    @State private var profileUploadProgress: Double? = nil
    @State private var idUploadProgress: Double? = nil
    @State private var errorMessage: String? = nil
    @EnvironmentObject var appRouter: AppRouter

    var body: some View {
        VStack(spacing: 24) {
            RegistrationStepHeader(
                title: "اثبات الهوية",
                subtitle: "قم برفع صورتك وصورة هويتك."
            )

            GeometryReader { geometry in
                VStack(spacing: 18) {
                    UploadBox(
                        title: mediaVM.getImage(for: .profileImage) == nil ? "قم بالضغط لرفع صورتك الشخصية" : "تم اختيار الصورة الشخصية",
                        image: mediaVM.getImage(for: .profileImage),
                        isUploading: uploadingProfile,
                        progress: profileUploadProgress,
                        onTap: { mediaVM.isPresentingPickerFor = .profileImage },
                        onUpload: {
                            if let image = mediaVM.getImage(for: .profileImage) {
                                uploadingProfile = true
                                profileUploadProgress = 0
                                NetworkManager.shared.uploadImage(
                                    image: image,
                                    progressHandler: { profileUploadProgress = $0 }
                                ) { result in
                                    uploadingProfile = false
                                    profileUploadProgress = nil
                                    switch result {
                                    case .success(let url):
                                        viewModel.imageURL = url
                                    case .failure(let error):
                                        errorMessage = "فشل رفع صورة البروفايل:\n\(error.localizedDescription)"
                                    }
                                }
                            }
                        },
                        onRemove: { mediaVM.removeMedia(for: .profileImage) }
                    )
                    .frame(maxHeight: (geometry.size.height - 16) / 2)

                    UploadBox(
                        title: mediaVM.getImage(for: .idImage) == nil ? "قم بالضغط لرفع صورة هويتك" : "تم اختيار صورة الهوية",
                        image: mediaVM.getImage(for: .idImage),
                        isUploading: uploadingID,
                        progress: idUploadProgress,
                        onTap: { mediaVM.isPresentingPickerFor = .idImage },
                        onUpload: {
                            if let image = mediaVM.getImage(for: .idImage) {
                                uploadingID = true
                                idUploadProgress = 0
                                NetworkManager.shared.uploadImage(
                                    image: image,
                                    progressHandler: { idUploadProgress = $0 }
                                ) { result in
                                    uploadingID = false
                                    idUploadProgress = nil
                                    switch result {
                                    case .success(let url):
                                        viewModel.idImageURL = url
                                    case .failure(let error):
                                        errorMessage = "فشل رفع صورة الهوية:\n\(error.localizedDescription)"
                                    }
                                }
                            }
                        },
                        onRemove: { mediaVM.removeMedia(for: .idImage) }
                    )
                    .frame(maxHeight: (geometry.size.height - 16) / 2)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .sheet(item: $mediaVM.isPresentingPickerFor) { _ in
            ImageVideoPicker(
                sourceType: mediaVM.sourceType,
                mediaTypes: ["public.image"]
            ) { img, _ in
                mediaVM.didSelectImage(img)
            }
        }
        .padding()
        .background(Color.background())
        .environment(\..layoutDirection, .rightToLeft)
        .bindLoadingState(viewModel.state, to: appRouter)
    }
}

struct UploadBox: View {
    var title: String
    var image: UIImage?
    var isUploading: Bool = false
    var progress: Double? = nil
    var onTap: () -> Void
    var onUpload: () -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onTap) {
                VStack(spacing: 10) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .yellowF8B22A().opacity(0.10), radius: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.primary(), lineWidth: 1)
                            )
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.yellowF8B22A())
                            .padding(25)
                    }
                    Text(title)
                        .customFont(weight: .medium, size: 14)
                        .foregroundColor(.primaryBlack())
                        .multilineTextAlignment(.center)
                        .padding(.top, 3)
                }
            }
            .buttonStyle(.plain)

            if image != nil && !isUploading {
                HStack(spacing: 20) {
                    Button(action: {
                        onUpload()
                    }) {
                        Label("رفع الصورة", systemImage: "icloud.and.arrow.up")
                            .customFont(weight: .medium, size: 13)
                            .foregroundColor(.yellowF8B22A())
                            .padding(.vertical, 7)
                            .padding(.horizontal, 18)
                            .background(Color.yellowF8B22A().opacity(0.11))
                            .cornerRadius(9)
                    }
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 19, weight: .regular))
                            .padding(.vertical, 7)
                            .padding(.horizontal, 10)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(9)
                    }
                }
            }

            if isUploading {
                VStack(spacing: 7) {
                    if let progress = progress {
                        AdvancedProgressView(
                            progress: progress,
                            icon: "person.crop.circle.fill",
                            color: .yellowF8B22A(),
                            bgColor: .gray.opacity(0.17),
                            size: 64,
                            text: "جاري رفع الصورة"
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .yellowF8B22A()))
                            .scaleEffect(1.1)
                    }
                }
                .padding(.top, 3)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: .infinity)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary(), lineWidth: 1.3)
        )
        .cornerRadius(18)
        .shadow(color: Color.primary().opacity(0.06), radius: 3, x: 0, y: 2)
        .contentShape(Rectangle())
        .animation(.easeInOut, value: isUploading)
    }
}

#Preview {
    RegistrationIdentityView(
        mediaVM: MediaPickerViewModel(),
        viewModel: RegistrationViewModel()
    )
}
