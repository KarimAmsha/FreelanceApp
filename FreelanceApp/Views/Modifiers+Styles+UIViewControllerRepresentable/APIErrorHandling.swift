import Foundation
import Alamofire

final class ErrorHandling {
    static let shared = ErrorHandling()
    private init() {}

    // MARK: - Main Handler
    func handleAPIError(_ error: Error) -> String {
        #if DEBUG
        print("🔴 [ErrorHandling] Error: \(error)")
        #endif

        switch error {
        case let apiError as APIClient.APIError:
            return handleAPIClientError(apiError)
        case let decodingError as DecodingError:
            return handleDecodingError(decodingError)
        case let afError as AFError:
            return handleAlamofireError(afError)
        case let urlError as URLError:
            return handleURLError(urlError)
        case let nsError as NSError:
            return nsError.localizedDescription.isEmpty ? "حدث خطأ غير متوقع!" : "خطأ: \(nsError.localizedDescription)"
        default:
            #if DEBUG
            print("🔴 [ErrorHandling][Default] Unhandled error: \(error)")
            #endif
            return "حدث خطأ غير متوقع!"
        }
    }

    // MARK: - APIClient Error
    private func handleAPIClientError(_ error: APIClient.APIError) -> String {
        #if DEBUG
        print("🟠 [ErrorHandling][APIClientError] \(error)")
        #endif
        switch error {
        case .networkError(let afError):      return handleAlamofireError(afError)
        case .badRequest:                     return "هناك خطأ في الطلب. يرجى التأكد من البيانات."
        case .unauthorized:                   return "الجلسة منتهية. يرجى إعادة تسجيل الدخول."
        case .invalidData:                    return "البيانات المستلمة غير صالحة."
        case .decodingError(let err):         return handleDecodingError(err)
        case .notFound:                       return "العنصر المطلوب غير موجود."
        case .serverError:                    return "حدث خطأ في الخادم. حاول لاحقًا."
        case .invalidToken:                   return "رمز الدخول غير صالح أو منتهي."
        case .customError(let msg):           return msg
        case .requestError(let afError):      return handleAlamofireError(afError)
        case .unknownError:                   return "حدث خطأ غير معروف."
        case .urlError(let urlError):         return handleURLError(urlError)
        case .thirdPartyError(let error):
            #if DEBUG
            print("🔴 [ErrorHandling][ThirdPartyError]: \(error)")
            #endif
            return "حدث خطأ من مكتبة خارجية: \((error as NSError).localizedDescription)"
        }
    }

    // MARK: - Alamofire Error
    private func handleAlamofireError(_ afError: AFError) -> String {
        #if DEBUG
        print("🟣 [ErrorHandling][AFError] \(afError)")
        #endif
        if let urlError = afError.underlyingError as? URLError {
            return handleURLError(urlError)
        }
        switch afError {
        case .invalidURL(let url):
            return "رابط غير صالح: \(url)"
        case .parameterEncodingFailed(let reason):
            return "فشل ترميز البيانات: \(reason)"
        case .multipartEncodingFailed(let reason):
            return "فشل ترميز الملفات: \(reason)"
        case .responseValidationFailed(let reason):
            return "فشل التحقق من الرد: \(reason)"
        case .responseSerializationFailed(let reason):
            return "خطأ في تحليل البيانات: \(reason)"
        default:
            return afError.errorDescription ?? String(describing: afError)
        }
    }

    // MARK: - Decoding Error
    private func handleDecodingError(_ error: DecodingError) -> String {
        #if DEBUG
        print("🔵 [ErrorHandling][DecodingError] \(error)")
        #endif
        switch error {
        case .dataCorrupted(let context):
            return "البيانات معطوبة: \(context.debugDescription)"
        case .keyNotFound(let key, let context):
            return "المفتاح '\(key.stringValue)' مفقود: \(context.debugDescription)"
        case .typeMismatch(let type, let context):
            return "نوع غير متطابق: \(type): \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "القيمة مفقودة: \(type): \(context.debugDescription)"
        @unknown default:
            return "خطأ في تحليل البيانات."
        }
    }

    // MARK: - URL Error
    private func handleURLError(_ urlError: URLError) -> String {
        #if DEBUG
        print("🟢 [ErrorHandling][URLError] \(urlError)")
        #endif
        switch urlError.code {
        case .notConnectedToInternet: return "لا يوجد اتصال بالإنترنت."
        case .timedOut:               return "انتهت مهلة الاتصال."
        case .cancelled:              return "تم إلغاء العملية."
        case .cannotFindHost:         return "الخادم غير متوفر."
        case .networkConnectionLost:  return "تم فقدان الاتصال بالشبكة."
        case .cannotConnectToHost:    return "تعذر الاتصال بالخادم. حاول لاحقًا."
        case .internationalRoamingOff: return "الاتصال غير ممكن بسبب إعدادات الشبكة."
        default:
            return "خطأ في الشبكة: \((urlError as NSError).localizedDescription)"
        }
    }
}
