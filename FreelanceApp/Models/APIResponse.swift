import Foundation

// بروتوكول موحد لكل الردود يدعم كل السيناريوهات
protocol APIBaseResponse: Decodable, Initializable {
    var status: Bool { get set }
    var message: String { get set }
    init()
}

// ميثاق يوفر init افتراضي لأي Struct جديد بسهولة
protocol Initializable {
    init()
}

// MARK: - استجابة مصفوفة (قائمة عناصر)
struct ArrayAPIResponse<T: Decodable>: APIBaseResponse {
    var status: Bool
    var message: String
    var items: [T]?
    var pagination: Pagination?

    init() {
        self.status = false
        self.message = ""
        self.items = nil
        self.pagination = nil
    }
}

// MARK: - استجابة عنصر واحد
struct SingleAPIResponse<T: Decodable>: APIBaseResponse {
    var status: Bool
    var message: String
    var items: T?

    // أضف init() حتى لو بعض الباك اند يعيد كود أو لا
    init() {
        self.status = false
        self.message = ""
        self.items = nil
    }

    // يمكن توسعة مع أي أكواد أو حقول إضافية حسب الحاجة
}

struct APIResponseCodable: APIBaseResponse, Decodable {
    var status: Bool = false
    var message: String = ""
}

// MARK: - استجابة بها كود أو حالة خاصة (مثل Tamara)
struct CodeAPIResponse<T: Decodable>: APIBaseResponse {
    var status: Bool
    var message: String
    var code: Int?
    var items: T?

    init() {
        self.status = false
        self.message = ""
        self.code = nil
        self.items = nil
    }
}

// MARK: - استجابة مخصصة (مع اختلاف الأسماء)
struct BaseCustomStatusAPIResponse<T: Decodable>: APIBaseResponse {
    var status: Bool
    var message: String
    var status_code: Int?
    var items: T?

    init() {
        self.status = false
        self.message = ""
        self.status_code = nil
        self.items = nil
    }
}

// MARK: - استجابة خاصة بالباك اند القديم (مثال)
struct WalletResponse: APIBaseResponse {
    var status: Bool
    var message: String
    var items: [WalletData]?
    var total: Double?
    var last_date: CustomDate?
    var status_code: Int?
    var messageAr: String?
    var messageEn: String?
    var pagenation: Pagination?

    init() {
        self.status = false
        self.message = ""
        self.items = nil
        self.total = nil
        self.last_date = nil
        self.status_code = nil
        self.messageAr = nil
        self.messageEn = nil
        self.pagenation = nil
    }
}

// MARK: - استجابة نصية بسيطة أو مخصصة
struct CustomApiResponse: APIBaseResponse {
    var status: Bool
    var message: String
    var status_code: Int?
    var messageAr: String?
    var messageEn: String?
    var items: String?

    init() {
        self.status = false
        self.message = ""
        self.status_code = nil
        self.messageAr = nil
        self.messageEn = nil
        self.items = nil
    }
}

// MARK: - Tamara Response
struct TamaraCheckoutResponse: APIBaseResponse {
    var status: Bool
    var message: String
    var code: Int?
    var items: TamaraCheckoutData?

    init() {
        self.status = false
        self.message = ""
        self.code = nil
        self.items = nil
    }
}

struct TamaraCheckoutData: Codable {
    let checkout_url: String?
}

// MARK: - نوع تاريخ مرن يدعم String أو Int
enum CustomDate: Codable {
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(CustomDate.self, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected to decode String or Int, but found neither."
            ))
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value):    try container.encode(value)
        }
    }
    func formattedDateString(with format: String) -> String? {
        switch self {
        case .string(let stringValue):
            return formatDateToString(createDateFromString(stringValue, format: format) ?? Date(), format: format)
        case .int(let intValue):
            let date = Date(timeIntervalSince1970: TimeInterval(intValue))
            return formatDateToString(date, format: format)
        }
    }
    private func formatDateToString(_ date: Date, format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    private func createDateFromString(_ dateString: String, format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: dateString)
    }
}

// MARK: - Dummy Type For Items If Needed
struct EmptyItems: Codable {}

// MARK: - Extension لدعم init() الافتراضي لأي Struct يحتاجه
extension Initializable {
    init() { self.init() }
}
