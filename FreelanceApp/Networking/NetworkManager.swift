import UIKit
import Alamofire

struct UploadImageResponse: Decodable {
    let status: Bool
    let code: Int?
    let message: String?
    let items: String?
}

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    // رابط رفع الصور النهائي ثابت
    private let imageUploadPath = "/mobile/image/upload"

    func uploadImage(
        image: UIImage,
        progressHandler: ((Double) -> Void)? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "فشل تحويل الصورة"])))
            return
        }

        // التوكن تلقائي
        guard let token = UserSettings.shared.token else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "غير مسجل الدخول"])))
            return
        }

        // بناء الرابط النهائي (موحد)
        let fullURL = Constants.baseURL + imageUploadPath

        let headers: HTTPHeaders = [
            "Accept-Language": "ar",
            "token": token
        ]

        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imageData, withName: "image", fileName: "photo.jpg", mimeType: "image/jpeg")
            },
            to: fullURL,
            headers: headers
        )
        .uploadProgress { progress in
            progressHandler?(progress.fractionCompleted)
        }
        .responseDecodable(of: UploadImageResponse.self) { response in
            switch response.result {
            case .success(let uploadResponse):
                if uploadResponse.status, let link = uploadResponse.items {
                    completion(.success(link))
                } else {
                    let message = uploadResponse.message ?? "حدث خطأ غير معروف"
                    completion(.failure(NSError(domain: "", code: uploadResponse.code ?? -1, userInfo: [NSLocalizedDescriptionKey: message])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
