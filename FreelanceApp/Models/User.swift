import Foundation
import CoreLocation

struct Point: Codable, Hashable {
    let type: String?
    let coordinates: [Double]?
    var location: CLLocationCoordinate2D? {
        guard let coords = coordinates, coords.count == 2 else { return nil }
        return CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
    }
}

struct User: Codable, Hashable, Identifiable {
    let id: String?
    var full_name: String?
    let reg_no: String?
    var email: String?
    let password: String?
    var phone_number: String?
    let image: String?
    let id_image: String?
    let dob: String?
    let gender: String?
    let os: String?
    let lat: Double?
    let lng: Double?
    let fcmToken: String?
    let verify_code: String?
    let isEnableNotifications: Bool?
    let token: String?
    let address: String?
    let city: String?
    let country: String?
    let work: String?
    let createAt: String?
    let isVerify: Bool?
    let isBlock: Bool?
    let wallet: Double?
    let rate: Double?
    let by: String?
    let bio: String?
    let register_type: String?
    let app_type: String?
    let loc: Point?
    let category: String?
    let subcategory: String?
    let services: Int?
    let profit: Int?
    let completed: Int?
    let isCompleteProfile: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case full_name, reg_no, email, password, phone_number, image, id_image, dob, gender, os, lat, lng
        case fcmToken, verify_code, isEnableNotifications, token, address, city, country, work
        case createAt, isVerify, isBlock, wallet, rate, by, bio, register_type, app_type, loc
        case category, subcategory, services, profit, completed, isCompleteProfile
    }
}

extension User {
    var formattedDOB: String? {
        guard let dob = dob else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date: Date? = isoFormatter.date(from: dob)
        if date == nil {
            let isoNoFraction = ISO8601DateFormatter()
            isoNoFraction.formatOptions = [.withInternetDateTime]
            date = isoNoFraction.date(from: dob)
        }
        guard let realDate = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: realDate)
    }
    
    var mainSpecialtyId: String? {
        if register_type == "personal" {
            return category
        } else if register_type == "company" {
            return work
        }
        return nil
    }
}

extension User {
    func withPhone(_ phone: String) -> User {
        var copy = self
        copy.phone_number = phone
        return copy
    }
    
    func withEmail(_ email: String) -> User { var copy = self; copy.email = email; return copy }
    func withName(_ name: String) -> User { var copy = self; copy.full_name = name; return copy }
}

extension User {
    init() {
        self.id = nil
        self.full_name = nil
        self.reg_no = nil
        self.email = nil
        self.password = nil
        self.phone_number = nil
        self.image = nil
        self.id_image = nil
        self.dob = nil
        self.gender = nil
        self.os = nil
        self.lat = nil
        self.lng = nil
        self.fcmToken = nil
        self.verify_code = nil
        self.isEnableNotifications = nil
        self.token = nil
        self.address = nil
        self.city = nil
        self.country = nil
        self.work = nil
        self.createAt = nil
        self.isVerify = nil
        self.isBlock = nil
        self.wallet = nil
        self.rate = nil
        self.by = nil
        self.bio = nil
        self.register_type = nil
        self.app_type = nil
        self.loc = nil
        self.category = nil
        self.subcategory = nil
        self.services = nil
        self.profit = nil
        self.completed = nil
        self.isCompleteProfile = nil
    }
}
