import SwiftUI
import AVFoundation

enum MediaType: String, Identifiable, CaseIterable {
    case profileImage
    case idImage
    case video
    case file
    var id: String { rawValue }
}

class MediaPickerViewModel: ObservableObject {
    @Published var images: [MediaType: UIImage] = [:]
    @Published var videos: [MediaType: URL] = [:]
    @Published var files: [MediaType: URL] = [:]
    @Published var isPresentingPickerFor: MediaType? = nil
    @Published var isPresentingDocumentPickerFor: MediaType? = nil

    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var mediaPickerType: MediaKind = .image

    enum MediaKind {
        case image, video
    }

    // عرض اختيار من الكاميرا أو الجالري
    func pickPhoto(for type: MediaType, fromCamera: Bool = false) {
        sourceType = fromCamera ? .camera : .photoLibrary
        mediaPickerType = .image
        isPresentingPickerFor = type
    }

    func pickVideo(for type: MediaType, fromCamera: Bool = false) {
        sourceType = fromCamera ? .camera : .photoLibrary
        mediaPickerType = .video
        isPresentingPickerFor = type
    }

    func pickFile(for type: MediaType) {
        isPresentingDocumentPickerFor = type
    }

    func didSelectImage(_ image: UIImage?) {
        guard let type = isPresentingPickerFor else { return }
        if let img = image { images[type] = img }
        isPresentingPickerFor = nil
    }

    func didSelectVideo(_ url: URL?) {
        guard let type = isPresentingPickerFor else { return }
        if let url = url { videos[type] = url }
        isPresentingPickerFor = nil
    }

    func didSelectFile(_ url: URL?) {
        guard let type = isPresentingDocumentPickerFor else { return }
        if let url = url { files[type] = url }
        isPresentingDocumentPickerFor = nil
    }

    func removeMedia(for type: MediaType) {
        images[type] = nil
        videos[type] = nil
        files[type] = nil
    }

    func getImage(for type: MediaType) -> UIImage? {
        images[type]
    }

    func getVideo(for type: MediaType) -> URL? {
        videos[type]
    }

    func getFile(for type: MediaType) -> URL? {
        files[type]
    }
}
