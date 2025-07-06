import SwiftUI
import AVFoundation

struct RegistrationIdentityView: View {
    @ObservedObject var mediaVM: MediaPickerViewModel
    @ObservedObject var viewModel: RegistrationViewModel
    @EnvironmentObject var errorManager: ErrorManager
    @State private var uploadingProfile = false
    @State private var uploadingID = false
    @State private var profileUploadProgress: Double? = nil
    @State private var idUploadProgress: Double? = nil

    var body: some View {
        VStack(spacing: 24) {
            RegistrationStepHeader(
                title: "اثبات الهوية",
                subtitle: "قم برفع صورتك وصورة هويتك."
            )

            GeometryReader { geometry in
                VStack(spacing: 16) {
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
                                    progressHandler: { progress in
                                        profileUploadProgress = progress
                                    }
                                ) { result in
                                    uploadingProfile = false
                                    profileUploadProgress = nil
                                    switch result {
                                    case .success(let url):
                                        viewModel.imageURL = url
                                    case .failure(let error):
                                        errorManager.show("فشل رفع صورة البروفايل:\n\(error.localizedDescription)")
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
                                    progressHandler: { progress in
                                        idUploadProgress = progress
                                    }
                                ) { result in
                                    uploadingID = false
                                    idUploadProgress = nil
                                    switch result {
                                    case .success(let url):
                                        viewModel.idImageURL = url
                                    case .failure(let error):
                                        errorManager.show("فشل رفع صورة الهوية:\n\(error.localizedDescription)")
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
        .sheet(item: $mediaVM.isPresentingPickerFor) { type in
            ImageVideoPicker(
                sourceType: mediaVM.sourceType,
                mediaTypes: ["public.image"]
            ) { img, url in
                mediaVM.didSelectImage(img)
            }
        }
        .overlay(
            VStack {
                if errorManager.show {
                    SnackbarErrorView(
                        message: errorManager.message,
                        type: errorManager.type
                    ) {
                        errorManager.hide()
                    }
                }
            }
        )
        .padding()
        .background(Color.background())
        .environment(\.layoutDirection, .rightToLeft)
    }
}

import SwiftUI

struct UploadBox: View {
    var title: String
    var image: UIImage?
    var isUploading: Bool = false
    var progress: Double? = nil // جديد: النسبة من 0.0 إلى 1.0 (أو nil لو مش لازم)
    var onTap: () -> Void
    var onUpload: () -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onTap) {
                VStack(spacing: 8) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(radius: 2)
                    } else {
                        Image(systemName: "camera")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.blue)
                            .padding(24)
                    }
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
            }
            .buttonStyle(.plain)

            if image != nil && !isUploading {
                HStack(spacing: 14) {
                    Button(action: onUpload) {
                        Label("رفع الصورة", systemImage: "icloud.and.arrow.up")
                            .font(.footnote)
                            .foregroundColor(.blue)
                            .padding(.vertical, 4)
                    }
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.body)
                    }
                }
            }

            if isUploading {
                VStack(spacing: 6) {
                    if let progress = progress {
                        ZStack {
                            ProgressView(value: progress)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.35)
                                .frame(width: 36, height: 36)
                            Text("\(Int(progress * 100))%")
                                .font(.caption2).bold()
                                .foregroundColor(.blue)
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                    }
                    Text("جاري الرفع...")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 1)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.18), style: StrokeStyle(lineWidth: 1.1, dash: [5]))
        )
        .cornerRadius(14)
        .shadow(color: .gray.opacity(0.08), radius: 3, x: 0, y: 2)
        .contentShape(Rectangle())
        .animation(.easeInOut, value: isUploading)
    }
}

#Preview {
    RegistrationIdentityView(
        mediaVM: MediaPickerViewModel(),
        viewModel: RegistrationViewModel(errorHandling: ErrorHandling())
    )
}
