import Foundation
import CoreLocation

struct Point: Codable, Hashable {
    let type: String?
    let coordinates: [Double]?
    
    // Optional computed property for convenience
    var location: CLLocationCoordinate2D? {
        guard let coords = coordinates, coords.count == 2 else { return nil }
        return CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1])
    }
}

struct User: Codable, Hashable, Identifiable {
    let id: String?
    let full_name: String?
    let reg_no: String?
    let email: String?
    let password: String?
    let phone_number: String?
    let image: String?
    let id_image: String?
    let dob: String?
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
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case full_name, reg_no, email, password, phone_number, image, id_image, dob, os, lat, lng
        case fcmToken, verify_code, isEnableNotifications, token, address, city, country, work
        case createAt, isVerify, isBlock, wallet, rate, by, bio, register_type, app_type, loc
        case category, subcategory, services, profit, completed
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
}
