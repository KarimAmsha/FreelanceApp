import SwiftUI
import AVFoundation

struct RegistrationIdentityView: View {
    @ObservedObject var mediaVM: MediaPickerViewModel
    @ObservedObject var viewModel: RegistrationViewModel
    @State private var uploadingProfile = false
    @State private var uploadingID = false

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
                        onTap: { mediaVM.isPresentingPickerFor = .profileImage },
                        onUpload: {
                            if let image = mediaVM.getImage(for: .profileImage) {
                                uploadingProfile = true
                                FirestoreService.shared.uploadImageWithThumbnail(image: image, id: viewModel.phone_number, imageName: "profile") { url, success in
                                    uploadingProfile = false
                                    if success, let url = url {
                                        viewModel.imageURL = url
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
                        onTap: { mediaVM.isPresentingPickerFor = .idImage },
                        onUpload: {
                            if let image = mediaVM.getImage(for: .idImage) {
                                uploadingID = true
                                FirestoreService.shared.uploadImageWithThumbnail(image: image, id: viewModel.phone_number, imageName: "id_card") { url, success in
                                    uploadingID = false
                                    if success, let url = url {
                                        viewModel.idImageURL = url
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
        .padding()
        .background(Color.background())
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct UploadBox: View {
    var title: String
    var image: UIImage?
    var isUploading: Bool = false
    var onTap: () -> Void
    var onUpload: () -> Void
    var onRemove: () -> Void

    var body: some View {
        VStack {
            Button(action: onTap) {
                VStack {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "camera")
                            .font(.system(size: 24))
                    }
                    Text(title)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            if image != nil && !isUploading {
                HStack {
                    Button("رفع الصورة", action: onUpload)
                        .padding(.vertical, 4)
                    Button(role: .destructive) {
                        onRemove()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            if isUploading {
                ProgressView("جاري الرفع...")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // يملأ كل مساحة البوكس
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
        )
        .cornerRadius(12)
        // أهم سطر يخلي المحتوى بالمنتصف دائمًا:
        .contentShape(Rectangle()) // يجعل منطقة الضغط وسط البوكس وليس فقط على النص/الصورة
    }
}

#Preview {
    RegistrationIdentityView(
        mediaVM: MediaPickerViewModel(),
        viewModel: RegistrationViewModel(errorHandling: ErrorHandling())
    )
}
