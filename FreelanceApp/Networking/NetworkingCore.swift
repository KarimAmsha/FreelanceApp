//
//  NetworkingCore.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 18.07.2025.
//

import Foundation
import Combine
import Alamofire

// MARK: - حالة التحميل

import Foundation

enum LoadingState: Equatable {
    case idle
    case loading
    case success(message: String? = nil)
    case failure(error: String)

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }

    var message: String? {
        switch self {
        case .success(let msg): return msg
        case .failure(let err): return err
        default: return nil
        }
    }

    var shouldShowMessage: Bool {
        switch self {
        case .success(let msg): return msg != nil && !msg!.isEmpty
        case .failure(let err): return !err.isEmpty
        default: return false
        }
    }
}

// MARK: - Encodable to Dictionary

extension Encodable {
    func asDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

// MARK: - GenericAPILoadable

@MainActor
protocol GenericAPILoadable: StateManaging {}

extension GenericAPILoadable {
    func fetchAPI<T: Decodable & APIBaseResponse>(
        endpoint: APIEndpoint,
        responseType: T.Type,
        onSuccess: @escaping (T) -> Void
    ) {
        prepareForLoading()

        DataProvider.shared.fetch(
            endpoint: endpoint,
            type: responseType,
            onSuccess: { [weak self] response in
                #if DEBUG
                print("✅ \(T.self) - Success message: \(response.message)")
                #endif
                self?.handleSuccess(message: response.message)
                onSuccess(response)
            },
            onFailure: { [weak self] errorMessage in
                #if DEBUG
                print("❌ \(T.self) - Error: \(errorMessage)")
                #endif
                self?.handleError(errorMessage)
            }
        )
    }
}

// MARK: - DataProvider

final class DataProvider {
    static let shared = DataProvider()
    private let apiClient = APIClient.shared
    private init() {}

    func fetch<T: Decodable & APIBaseResponse>(
        endpoint: APIEndpoint,
        type: T.Type,
        onSuccess: @escaping (T) -> Void,
        onFailure: ((String) -> Void)? = nil
    ) {
        apiClient.request(endpoint: endpoint, responseType: T.self) { result in
            switch result {
            case .success(let response):
                if response.status {
                    onSuccess(response)
                } else {
                    let msg = response.message.isEmpty ? "حدث خطأ أثناء العملية." : response.message
                    onFailure?(msg)
                }
            case .failure(let error):
                let msg = ErrorHandling.shared.handleAPIError(error)
                onFailure?(msg)
            }
        }
    }
}

// MARK: - APIClient

final class APIClient {
    static let shared = APIClient()
    private var activeRequest: DataRequest?
    private init() {}

    enum APIError: Error {
        case networkError(AFError)
        case urlError(URLError)
        case invalidData
        case decodingError(DecodingError)
        case requestError(AFError)
        case unauthorized
        case notFound
        case badRequest
        case serverError
        case invalidToken
        case customError(message: String)
        case thirdPartyError(error: Error)
        case unknownError

        var debugDescription: String {
            switch self {
            case .networkError(let afError): return "NetworkError: \(afError)"
            case .urlError(let urlError):    return "URLError: \(urlError)"
            case .invalidData:               return "InvalidData"
            case .decodingError(let err):    return "DecodingError: \(err)"
            case .requestError(let afError): return "RequestError: \(afError)"
            case .unauthorized:              return "Unauthorized"
            case .notFound:                  return "NotFound"
            case .badRequest:                return "BadRequest"
            case .serverError:               return "ServerError"
            case .invalidToken:              return "InvalidToken"
            case .customError(let msg):      return "Custom: \(msg)"
            case .thirdPartyError(let error):return "ThirdPartyError: \(error)"
            case .unknownError:              return "UnknownError"
            }
        }
    }

    func request<T: Decodable>(
        endpoint: APIEndpoint,
        responseType: T.Type,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        let encoding = endpoint.encoding

        if endpoint.method == .get {
            // فقط GET: الكويري باراميترز في الـ URL، ولا ترسل body!
            activeRequest = AF.request(
                endpoint.url!, // الـ url فيه الكويري تلقائيًا عبر URLComponents
                method: .get,
                headers: endpoint.headers
            )
            .validate()
            .responseData { response in
                self.decodeApiResponse(response: response, completion: completion)
            }
        } else {
            // POST/PUT/...: الكويري في الـ url، والـ body في parameters
            activeRequest = AF.request(
                endpoint.url!,
                method: endpoint.method,
                parameters: endpoint.bodyParameters,
                encoding: encoding,
                headers: endpoint.headers
            )
            .validate()
            .responseData { response in
                self.decodeApiResponse(response: response, completion: completion)
            }
        }
    }

    func decodeApiResponse<T: Decodable>(
        response: AFDataResponse<Data>,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        switch response.result {
        case .success(let data):
            print("🎯 RAW DATA:", String(data: data, encoding: .utf8) ?? "")
            do {
                let statusCode = response.response?.statusCode ?? 0
                switch statusCode {
                case 200:
                    let decodedData = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decodedData))
                case 400: completion(.failure(.badRequest))
                case 401: completion(.failure(.unauthorized))
                case 404: completion(.failure(.notFound))
                case 430: completion(.failure(.invalidToken))
                case 500...599: completion(.failure(.serverError))
                default:
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    completion(.failure(.customError(message: message)))
                }
            } catch let decodingError as DecodingError {
                completion(.failure(mapDecodingError(decodingError)))
            } catch {
                completion(.failure(.unknownError))
            }
        case .failure(let error):
            completion(.failure(.networkError(error)))
        }
    }

    func mapDecodingError(_ error: Error) -> APIError {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                return .customError(message: "Data corrupted: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                return .customError(message: "Key '\(key.stringValue)' not found: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                return .customError(message: "Type mismatch, expected \(type): \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                return .customError(message: "Value not found, expected \(type): \(context.debugDescription)")
            @unknown default:
                return .decodingError(decodingError)
            }
        }
        return .unknownError
    }

    func cancelRequest() {
        activeRequest?.cancel()
    }
}
