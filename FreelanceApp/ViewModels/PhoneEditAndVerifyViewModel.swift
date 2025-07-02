import SwiftUI
import Combine

enum PhoneChangeStep {
    case enterOldPhone
    case verifyOldPhone
    case enterNewPhone
    case verifyNewPhone
    case success
}

class PhoneChangeViewModel: ObservableObject {
    @Published var step: PhoneChangeStep = .enterOldPhone

    // الهاتف الحالي
    @Published var oldPhone: String = UserSettings.shared.user?.phone_number ?? ""
    @Published var oldOtp: String = ""
    @Published var showOldOtpPopup: Bool = false

    // الهاتف الجديد
    @Published var newPhone: String = ""
    @Published var newOtp: String = ""
    @Published var showNewOtpPopup: Bool = false

    @Published var countryCode: String = "+966"
    @State var countryFlag : String = "🇸🇦"

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var timer: Int = 59
    @Published var canResend: Bool = false

    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private let errorHandling: ErrorHandling

    @Published var user: User? = UserSettings.shared.user

    init(errorHandling: ErrorHandling) {
        self.errorHandling = errorHandling
    }

    // ========== الخطوة الأولى: تحقق من الهاتف الحالي ==========
    func requestOldOtp() {
        errorMessage = nil
        isLoading = true
        // هنا عادة ترسل كود التحقق للهاتف الحالي عبر API منفصل (مثلاً endpoint: sendOtp)
        // عندك يمكن نفس تعديل الهاتف (أو تحقق أولي) يرسل الكود تلقائياً
        // سنعتبر هنا أنك عندك endpoint منفصل اسمه sendOtpOld (إن وجد أضفه حسب النظام)
        // في معظم الأنظمة يكفي أن تذهب مباشرة للبوب أب وتبدأ التايمر
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.isLoading = false
            self.showOldOtpPopup = true
            self.startTimer()
        }
    }

    func verifyOldOtp(completion: @escaping (Bool) -> Void) {
        errorMessage = nil
        isLoading = true

        // دالة verify الحقيقية:
        guard let id = user?.id else {
            self.errorMessage = "معرّف المستخدم غير متوفر"
            self.isLoading = false
            completion(false)
            return
        }

        let request = VerifyRequest(
            id: id,
            verify_code: oldOtp,
            phone_number: completeOldPhone()
        )

        DataProvider.shared.sendRequest(
            endpoint: .verify(params: request.asDictionary() ?? [:]),
            body: request,
            responseType: SingleAPIResponse<User>.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let apiResponse):
                    if apiResponse.status {
                        self?.showOldOtpPopup = false
                        self?.step = .enterNewPhone
                        completion(true)
                    } else {
                        self?.errorMessage = apiResponse.message
                        completion(false)
                    }
                case .failure(let error):
                    self?.handleAPIError(error)
                    completion(false)
                }
            }
        }
    }

    // ========== الخطوة الثانية: تعديل الهاتف الجديد ==========
    func updateNewPhone() {
        guard let token = UserSettings.shared.token else {
            self.handleAPIError(.customError(message: LocalizedStringKey.tokenError))
            return
        }

        errorMessage = nil
        isLoading = true

        guard let id = user?.id else {
            self.errorMessage = "معرّف المستخدم غير متوفر"
            self.isLoading = false
            return
        }

        let editRequest = EditPhoneRequest(
            id: id,
            phone_number: completeNewPhone()
        )

        DataProvider.shared.sendRequest(
            endpoint: .editPhone(params: editRequest.asDictionary() ?? [:], token: token),
            body: editRequest,
            responseType: SingleAPIResponse<User>.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let apiResponse):
                    if apiResponse.status {
                        self?.showNewOtpPopup = true
                        self?.startTimer()
                    } else {
                        self?.errorMessage = apiResponse.message
                    }
                case .failure(let error):
                    self?.handleAPIError(error)
                }
            }
        }
    }

    // تحقق الكود للهاتف الجديد (verify حقيقية أيضًا)
    func verifyNewOtp(completion: @escaping (Bool) -> Void) {
        errorMessage = nil
        isLoading = true

        guard let id = user?.id else {
            self.errorMessage = "معرّف المستخدم غير متوفر"
            self.isLoading = false
            completion(false)
            return
        }

        let request = VerifyRequest(
            id: id,
            verify_code: newOtp,
            phone_number: completeNewPhone()
        )

        DataProvider.shared.sendRequest(
            endpoint: .verify(params: request.asDictionary() ?? [:]),
            body: request,
            responseType: SingleAPIResponse<User>.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let apiResponse):
                    if apiResponse.status, let user = apiResponse.items {
                        self?.user = user
                        UserSettings.shared.user = user
                        self?.showNewOtpPopup = false
                        self?.step = .success
                        completion(true)
                    } else {
                        self?.errorMessage = apiResponse.message
                        completion(false)
                    }
                case .failure(let error):
                    self?.handleAPIError(error)
                    completion(false)
                }
            }
        }
    }

    // ========== إعادة إرسال الكود ==========
    func resendOldOtp() {
        errorMessage = nil
        isLoading = true
        guard let id = user?.id else {
            self.errorMessage = "معرّف المستخدم غير متوفر"
            self.isLoading = false
            return
        }
        let params = ["id": id]
        let endpoint = DataProvider.Endpoint.resend(params: params)
        DataProvider.shared.request(endpoint: endpoint, responseType: SingleAPIResponse<User>.self)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.handleAPIError(error)
                    self?.isLoading = false
                }
            }, receiveValue: { [weak self] (response: SingleAPIResponse<User>) in
                self?.isLoading = false
                if response.status {
                    self?.startTimer()
                } else {
                    self?.handleAPIError(.customError(message: response.message))
                }
            })
            .store(in: &cancellables)
    }

    func resendNewOtp() {
        resendOldOtp() // إذا نفس المنطق - وإلا كرر وأرسل للهاتف الجديد
    }

    // ========== أدوات مساعدة ==========
    // إرسال الرقم القديم
    func completeOldPhone() -> String {
        normalizePhone(countryCode: countryCode, phone: oldPhone)
    }

    // إرسال الرقم الجديد
    func completeNewPhone() -> String {
        normalizePhone(countryCode: countryCode, phone: newPhone)
    }
    private func handleAPIError(_ error: APIClient.APIError) {
        let errorDescription = errorHandling.handleAPIError(error)
        errorMessage = errorDescription
    }

    private func handleAPIError(_ error: Error) {
        if let apiError = error as? APIClient.APIError {
            self.errorMessage = errorHandling.handleAPIError(apiError)
        } else {
            self.errorMessage = error.localizedDescription
        }
    }
    func startTimer() {
        timerCancellable?.cancel()
        timer = 59
        canResend = false
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timer > 0 {
                    self.timer -= 1
                }
                if self.timer == 0 {
                    self.canResend = true
                    self.timerCancellable?.cancel()
                }
            }
    }
    
    func normalizePhone(countryCode: String, phone: String) -> String {
        // كود الدولة بدون زائد
        let code = countryCode.replacingOccurrences(of: "+", with: "")

        // الرقم المدخل، فقط أرقام
        var mobile = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        // إذا الرقم يبدأ بكود الدولة، احذفه
        if mobile.hasPrefix(code) {
            mobile = String(mobile.dropFirst(code.count))
        }

        // الناتج: كود الدولة (مرة واحدة) + الرقم المحلي
        return code + mobile
    }
}

// نماذج الريكوست
struct EditPhoneRequest: Codable {
    let id: String
    let phone_number: String
    func asDictionary() -> [String: Any]? {
        try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self)) as? [String: Any]
    }
}
