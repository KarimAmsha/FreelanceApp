//
//  ImageVideoPicker.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 24.06.2025.
//

import SwiftUI

struct ImageVideoPicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var mediaTypes: [String] = ["public.image"] // ["public.image", "public.movie"] للفيديو

    var completion: (UIImage?, URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.mediaTypes = mediaTypes
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completion: (UIImage?, URL?) -> Void
        init(completion: @escaping (UIImage?, URL?) -> Void) { self.completion = completion }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL { // فيديو
                completion(nil, url)
            } else if let image = info[.originalImage] as? UIImage { // صورة
                completion(image, nil)
            } else {
                completion(nil, nil)
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil, nil)
            picker.dismiss(animated: true)
        }
    }
}
