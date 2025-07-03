import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject {
    // Singleton (استخدمها إذا بدك مدير موحد لكل التطبيق)
    static let shared = LocationManager()
    
    // MARK: - Core Location
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // MARK: - Published Vars (تراقبها SwiftUI)
    @Published var location: CLLocation?
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var address: String = ""
    @Published var isLoading: Bool = false
    @Published var permissionDenied: Bool = false
    @Published var locationServicesDisabled: Bool = false
    @Published var errorMessage: String? = nil
    @Published var updatingContinuously: Bool = false   // 🔥 هل أنت بوضع "تتبع مستمر" أم لا؟
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - طلب الموقع مرة واحدة فقط (الأكثر شيوعاً)
    func requestLocationOnce() {
        isLoading = true
        updatingContinuously = false
        errorMessage = nil
        if !CLLocationManager.locationServicesEnabled() {
            self.locationServicesDisabled = true
            self.isLoading = false
            self.errorMessage = "خدمات الموقع غير مفعلة."
            return
        }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            self.permissionDenied = true
            self.isLoading = false
            self.errorMessage = "لم يتم السماح بالوصول للموقع. فعّل الصلاحيات من الإعدادات."
        case .authorizedWhenInUse, .authorizedAlways:
            permissionDenied = false
            locationServicesDisabled = false
            locationManager.requestLocation()
        @unknown default:
            self.errorMessage = "حالة صلاحية الموقع غير معروفة!"
            self.isLoading = false
        }
    }
    
    // MARK: - تتبع الموقع بشكل مستمر (مثلاً إذا بدك ملاحة أو متابعة live)
    func startContinuousUpdates() {
        isLoading = true
        updatingContinuously = true
        errorMessage = nil
        if !CLLocationManager.locationServicesEnabled() {
            self.locationServicesDisabled = true
            self.isLoading = false
            self.errorMessage = "خدمات الموقع غير مفعلة."
            return
        }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            self.permissionDenied = true
            self.isLoading = false
            self.errorMessage = "لم يتم السماح بالوصول للموقع. فعّل الصلاحيات من الإعدادات."
        case .authorizedWhenInUse, .authorizedAlways:
            permissionDenied = false
            locationServicesDisabled = false
            locationManager.startUpdatingLocation()
        @unknown default:
            self.errorMessage = "حالة صلاحية الموقع غير معروفة!"
            self.isLoading = false
        }
    }
    
    func stopContinuousUpdates() {
        updatingContinuously = false
        locationManager.stopUpdatingLocation()
        isLoading = false
    }
    
    // MARK: - جلب العنوان من اللوكيشن
    private func fetchAddress(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.address = ""
                    self?.errorMessage = "فشل جلب العنوان: \(error.localizedDescription)"
                    return
                }
                if let placemark = placemarks?.first {
                    let addressString = [
                        placemark.name,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }.joined(separator: ", ")
                    self?.address = addressString
                } else {
                    self?.address = ""
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // التعامل مع الصلاحيات الجديدة
        if updatingContinuously {
            startContinuousUpdates()
        } else {
            requestLocationOnce()
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManagerDidChangeAuthorization(manager)
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoading = false
        guard let loc = locations.last else { return }
        self.location = loc
        self.latitude = loc.coordinate.latitude
        self.longitude = loc.coordinate.longitude
        self.userCoordinate = loc.coordinate
        self.fetchAddress(for: loc)
        // إذا بوضع "مرة واحدة"، لا داعي لأي شيء إضافي، وإذا بوضع تتبع، سيستمر بالتحديث.
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "فشل تحديث الموقع: \(error.localizedDescription)"
        isLoading = false
    }
}
