//
//  APIEndpoint.swift
//  FreelanceApp
//
//  Created by Karim OTHMAN on 18.07.2025.
//

import Foundation
import Alamofire

private let BASE_URL = Constants.baseURL

func getUserPreferredLanguageCode() -> String {
    Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "ar"
}

// MARK: - API Endpoint Enum

enum APIEndpoint {
    case getWelcome
    case getConstants
    case getConstantDetails(_id: String)
    case getUserProfile(token: String)
    case getCategories
    case getHome
    case getContact
    case getAppConstants
    case guest
    case getProductDetails(id: String, token: String)
    case getCartItems(token: String)
    case cartCount(token: String)
    case cartTotal(token: String)
    case getFavorite(page: Int?, limit: Int?, token: String)
    case getWishGroups(page: Int?, limit: Int?, user_id: String?, token: String)
    case getGroup(id: String, token: String)
    case getFriends(page: Int?, limit: Int?, token: String)
    case getNotifications(page: Int?, limit: Int?, token: String)
    case getAddressList(token: String)
    case getWish(id: String, token: String)

    case searchFreelancers(page: Int?, limit: Int?, body: Encodable, token: String)
    case register(body: Encodable)
    case verify(body: Encodable)
    case resend(body: Encodable)
    case updateUserData(body: Encodable, token: String)
    case logout(userID: String, token: String)
    case addOrder(body: Encodable, token: String)
    case getOrders(status: String?, page: Int?, limit: Int?, token: String)
    case addReview(orderID: String, body: Encodable, token: String)
    case deleteNotification(id: String, token: String)
    case getWallet(page: Int?, limit: Int?, token: String)
    case addBalanceToWallet(body: Encodable, token: String)
    case addComplain(body: Encodable, token: String)
    case createReferral(token: String)
    case checkCoupon(body: Encodable, token: String)
    case addAddress(body: Encodable, token: String)
    case updateAddress(body: Encodable, token: String)
    case deleteAddress(id: String, token: String)
    case getAddressByType(type: String, token: String)
    case getTotalPrices(body: Encodable, token: String)
    case deleteAccount(id: String, token: String)
    case tamaraCheckout(body: Encodable, token: String)
    case checkPlace(body: Encodable, token: String)
    case checkPoint(body: Encodable, token: String)
    case rechangePoint(body: Encodable, token: String)
    case getProducts(page: Int?, limit: Int?, body: Encodable, token: String)
    case addToCart(body: Encodable, token: String)
    case updateCartItems(body: Encodable, token: String)
    case deleteCart(token: String)
    case deleteCartItem(body: Encodable, token: String)
    case addToFavorite(body: Encodable, token: String)
    case addGroup(body: Encodable, token: String)
    case editGroup(id: String, body: Encodable, token: String)
    case deleteGroup(id: String, token: String)
    case addFriend(body: Encodable, token: String)
    case explore(page: Int?, limit: Int?, token: String)
    case reminder(page: Int?, limit: Int?, token: String)
    case addReminder(body: Encodable, token: String)
    case deleteReminder(id: String, body: Encodable, token: String)
    case addUserProduct(body: Encodable, token: String)
    case addVIP(body: Encodable, token: String)
    case addWish(body: Encodable, token: String)
    case getUserWishes(page: Int?, limit: Int?, body: Encodable, token: String)
    case payWish(id: String, body: Encodable, token: String)
    case checkCartCoupon(body: Encodable, token: String)
    case addOrderWish(body: Encodable, token: String)
    case refreshFcmToken(body: Encodable, token: String)
    case editPhone(body: Encodable, token: String)
}

// MARK: - Properties

extension APIEndpoint {
    var path: String {
        switch self {
        case .getWelcome: return "/mobile/constant/welcome"
        case .getConstants: return "/mobile/constant/static"
        case .getConstantDetails(let id): return "/mobile/constant/static/\(id)"
        case .getUserProfile: return "/mobile/user/get-user"
        case .getCategories: return "/mobile/constant/category"
        case .getHome: return "/mobile/home/get"
        case .getContact: return "/mobile/constant/contact_options"
        case .getAppConstants: return "/mobile/constant/get"
        case .guest: return "/mobile/guest/token"
        case .getProductDetails(let id, _): return "/mobile/products/details/\(id)"
        case .getCartItems: return "/mobile/cart/get"
        case .cartCount: return "/mobile/cart/count"
        case .cartTotal: return "/mobile/cart/total"
        case .getFavorite: return "/mobile/favorite/get"
        case .getWishGroups: return "/mobile/wish_group/get"
        case .getGroup(let id, _): return "/mobile/wish_group/get/\(id)"
        case .getFriends: return "/mobile/friend/list"
        case .getNotifications: return "/mobile/notification/get"
        case .getAddressList: return "/mobile/user/get_address"
        case .getWish(let id, _): return "/mobile/wish/get/\(id)"
        case .searchFreelancers: return "/mobile/home/search"
        case .register: return "/mobile/user/create_login"
        case .verify: return "/mobile/user/verify"
        case .resend: return "/mobile/user/resend"
        case .updateUserData: return "/mobile/user/update-profile"
        case .logout(let id, _): return "/mobile/user/logout/\(id)"
        case .addOrder: return "/mobile/order/add"
        case .getOrders: return "/mobile/order/get"
        case .addReview(let id, _, _): return "/mobile/order/rate/\(id)"
        case .deleteNotification(let id, _): return "/mobile/notification/delete/\(id)"
        case .getWallet: return "/mobile/transaction/list"
        case .addBalanceToWallet: return "/mobile/user/wallet"
        case .addComplain: return "/mobile/constant/add-complain"
        case .createReferral: return "/mobile/user/referal"
        case .checkCoupon: return "/mobile/check/coupon"
        case .addAddress: return "/mobile/user/add_address"
        case .updateAddress: return "/mobile/user/update_address"
        case .deleteAddress: return "/mobile/user/delete_address"
        case .getAddressByType(let type, _): return "/mobile/user/get_address/\(type)"
        case .getTotalPrices: return "/mobile/order/totals"
        case .deleteAccount(let id, _): return "/mobile/delete/\(id)"
        case .tamaraCheckout: return "/mobile/checkout"
        case .checkPlace: return "/mobile/check/place"
        case .checkPoint: return "/mobile/point/check"
        case .rechangePoint: return "/mobile/user/rechange"
        case .getProducts: return "/mobile/product/list"
        case .addToCart: return "/mobile/cart/add"
        case .updateCartItems: return "/mobile/cart/update"
        case .deleteCart: return "/mobile/cart/delete-cart"
        case .deleteCartItem: return "/mobile/cart/delete"
        case .addToFavorite: return "/mobile/favorite/add"
        case .addGroup: return "/mobile/wish_group/add"
        case .editGroup(let id, _, _): return "/mobile/wish_group/edit/\(id)"
        case .deleteGroup(let id, _): return "/mobile/wish_group/delete/\(id)"
        case .addFriend: return "/mobile/friend/add"
        case .explore: return "/mobile/wish/explore"
        case .reminder: return "/mobile/reminder/get"
        case .addReminder: return "/mobile/reminder/add"
        case .deleteReminder(let id, _, _): return "/mobile/reminder/delete/\(id)"
        case .addUserProduct: return "/mobile/form/product"
        case .addVIP: return "/mobile/form/vip"
        case .addWish: return "/mobile/wish/add"
        case .getUserWishes: return "/mobile/wish/get"
        case .payWish(let id, _, _): return "/mobile/wish/pay/\(id)"
        case .checkCartCoupon: return "/mobile/cart/coupon"
        case .addOrderWish: return "/mobile/order/add_wish"
        case .refreshFcmToken: return "/mobile/user/refresh-fcm-token"
        case .editPhone: return "/mobile/user/update-phone"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getWelcome, .getConstants, .getConstantDetails, .getUserProfile,
             .getCategories, .getHome, .getContact, .getAppConstants,
             .guest, .getProductDetails, .getCartItems, .cartCount,
             .cartTotal, .getFavorite, .getWishGroups, .getGroup,
             .getFriends, .getNotifications, .getAddressList, .getWish,
             .getOrders, .getWallet, .explore, .reminder:
            return .get
        default:
            return .post
        }
    }

    var queryParameters: [String: Any]? {
        switch self {
        case .getNotifications(let page, let limit, _),
             .getWallet(let page, let limit, _),
             .getProducts(let page, let limit, _, _),
             .getFavorite(let page, let limit, _),
             .getWishGroups(let page, let limit, _, _),
             .getOrders(_, let page, let limit, _),
             .getFriends(let page, let limit, _),
             .explore(let page, let limit, _),
             .reminder(let page, let limit, _),
             .getUserWishes(let page, let limit, _, _),
             .searchFreelancers(let page, let limit, _, _):
            return ["page": page ?? 1, "limit": limit ?? 20]
        default:
            return nil
        }
    }

    var fullURL: String { BASE_URL + path }
    var url: URL? {
        // اجمع الرابط الأساسي
        guard var components = URLComponents(string: fullURL) else { return nil }

        // أضف الكويري باراميترز إن وجدت
        if let queryParameters = queryParameters, !queryParameters.isEmpty {
            let queryItems = queryParameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            // أدمج مع أي query موجودة أصلاً في الرابط
            if let existing = components.queryItems {
                components.queryItems = existing + queryItems
            } else {
                components.queryItems = queryItems
            }
        }
        return components.url
    }
}

// MARK: - Headers

extension APIEndpoint {
    var token: String? {
        switch self {
        case .getUserProfile(let token),
             .getProductDetails(_, let token),
             .getCartItems(let token),
             .cartCount(let token),
             .cartTotal(let token),
             .getFavorite(_, _, let token),
             .getWishGroups(_, _, _, let token),
             .getGroup(_, let token),
             .getFriends(_, _, let token),
             .getNotifications(_, _, let token),
             .getAddressList(let token),
             .getWish(_, let token),
             .getOrders(_, _, _, let token),
             .getWallet(_, _, let token),
             .getUserWishes(_, _, _, let token),
             .deleteNotification(_, let token),
             .deleteAddress(_, let token),
             .deleteGroup(_, let token),
             .deleteReminder(_, _, let token),
             .deleteAccount(_, let token),
             .logout(_, let token),
             .getAddressByType(_, let token),
             .createReferral(let token),
             .checkCoupon(_, let token),
             .addBalanceToWallet(_, let token),
             .addComplain(_, let token),
             .searchFreelancers(_, _, _, let token),
             .updateUserData(_, let token),
             .addOrder(_, let token),
             .addReview(_, _, let token),
             .addAddress(_, let token),
             .updateAddress(_, let token),
             .tamaraCheckout(_, let token),
             .checkPlace(_, let token),
             .checkPoint(_, let token),
             .rechangePoint(_, let token),
             .addToCart(_, let token),
             .updateCartItems(_, let token),
             .deleteCart(let token),
             .deleteCartItem(_, let token),
             .addToFavorite(_, let token),
             .addGroup(_, let token),
             .editGroup(_, _, let token),
             .addFriend(_, let token),
             .addReminder(_, let token),
             .addUserProduct(_, let token),
             .addVIP(_, let token),
             .addWish(_, let token),
             .payWish(_, _, let token),
             .addOrderWish(_, let token),
             .checkCartCoupon(_, let token),
             .refreshFcmToken(_, let token),
             .editPhone(_, let token):
            return token
        default:
            return nil
        }
    }

    var headers: HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: "Accept-Language", value: getUserPreferredLanguageCode())
        if let token = token {
            headers.add(name: "token", value: token)
        }
        return headers
    }
}

extension APIEndpoint {
    var bodyParameters: Parameters? {
        if method == .get { return nil }
        switch self {
        case .register(let body),
             .verify(let body),
             .resend(let body),
             .updateUserData(let body, _),
             .addOrder(let body, _),
             .addReview(_, let body, _),
             .checkCoupon(let body, _),
             .addAddress(let body, _),
             .updateAddress(let body, _),
             .deleteCartItem(let body, _),
             .addToFavorite(let body, _),
             .addGroup(let body, _),
             .editGroup(_, let body, _),
             .addFriend(let body, _),
             .addReminder(let body, _),
             .addUserProduct(let body, _),
             .addVIP(let body, _),
             .addWish(let body, _),
             .payWish(_, let body, _),
             .addOrderWish(let body, _),
             .checkCartCoupon(let body, _),
             .rechangePoint(let body, _),
             .checkPoint(let body, _),
             .checkPlace(let body, _),
             .refreshFcmToken(let body, _),
             .editPhone(let body, _),
             .tamaraCheckout(let body, _),
             .addBalanceToWallet(let body, _),
             .addComplain(let body, _),
             .deleteReminder(_, let body, _),
             .getTotalPrices(let body, _),
             .addToCart(let body, _),
             .updateCartItems(let body, _),
             .getUserWishes(_, _, let body, _),
             .getProducts(_, _, let body, _),
             .searchFreelancers(_, _, let body, _):
            return body.asDictionary()
        default:
            return nil
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .searchFreelancers:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }
}
