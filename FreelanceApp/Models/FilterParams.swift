//
//  FilterParams.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 2.07.2025.
//

import SwiftUI

struct FilterParams {
    var category: String?
    var long: Double?
    var lat: Double?
    var distanceFrom: Int?
    var distanceTo: Int?
    var rateFrom: Int?
    var rateTo: Int?
    var profitFrom: Int?
    var profitTo: Int?
    var name: String?
    
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let category = category { dict["category"] = category }
        if let long = long { dict["long"] = long }
        if let lat = lat { dict["lat"] = lat }
        if let distanceFrom = distanceFrom { dict["distance_from"] = distanceFrom }
        if let distanceTo = distanceTo { dict["distance_to"] = distanceTo }
        if let rateFrom = rateFrom { dict["rate_from"] = rateFrom }
        if let rateTo = rateTo { dict["rate_to"] = rateTo }
        if let profitFrom = profitFrom { dict["profit_from"] = profitFrom }
        if let profitTo = profitTo { dict["profit_to"] = profitTo }
        if let name = name { dict["name"] = name }
        return dict
    }
}

