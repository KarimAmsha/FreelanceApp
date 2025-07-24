import Foundation
import CoreLocation
import Combine

// MARK: - Location Manager
@MainActor
final class LocationManager: NSObject, ObservableObject, StateManaging {

    // MARK: - Singleton
    static let shared = LocationManager()

    // MARK: - Core Location Components
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    // MARK: - Routing (Optional)
    var appRouter: AppRouter?

    // MARK: - Published Properties
    @Published var state: LoadingState = .idle
    @Published var location: CLLocation?
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var address: String = ""
    @Published var placemark: CLPlacemark?
    @Published var permissionDenied: Bool = false
    @Published var locationServicesDisabled: Bool = false
    @Published var updatingContinuously: Bool = false

    // Callback for external updates
    var onLocationUpdate: ((CLLocation) -> Void)? = nil

    // MARK: - Init
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public Methods
    func requestLocationOnce() {
        prepareForRequest(isContinuous: false)
        validateAuthorization()
    }

    func startContinuousUpdates() {
        prepareForRequest(isContinuous: true)
        validateAuthorization()
    }

    func stopContinuousUpdates() {
        updatingContinuously = false
        locationManager.stopUpdatingLocation()
        state = .idle
    }

    // MARK: - Internal State Management
    private func prepareForRequest(isContinuous: Bool) {
        state = .loading
        updatingContinuously = isContinuous
        if !CLLocationManager.locationServicesEnabled() {
            locationServicesDisabled = true
            state = .failure(error: "خدمات الموقع غير مفعلة.")
        }
    }

    private func validateAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            permissionDenied = true
            state = .failure(error: "لم يتم السماح بالوصول للموقع. فعّل الصلاحيات من الإعدادات.")
        case .authorizedWhenInUse, .authorizedAlways:
            permissionDenied = false
            locationServicesDisabled = false
            updatingContinuously ? locationManager.startUpdatingLocation() : locationManager.requestLocation()
        @unknown default:
            state = .failure(error: "حالة صلاحية الموقع غير معروفة!")
        }
    }

    private func fetchAddress(for location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.address = ""
                    self?.placemark = nil
                    self?.state = .failure(error: "فشل جلب العنوان: \(error.localizedDescription)")
                    return
                }
                if let placemark = placemarks?.first {
                    self?.placemark = placemark
                    let addressString = [
                        placemark.name,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }.joined(separator: ", ")
                    self?.address = addressString
                    self?.state = .success()
                } else {
                    self?.address = ""
                    self?.placemark = nil
                    self?.state = .success()
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.updatingContinuously ? self.startContinuousUpdates() : self.requestLocationOnce()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManagerDidChangeAuthorization(manager)
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.state = .loading
            self.location = loc
            self.latitude = loc.coordinate.latitude
            self.longitude = loc.coordinate.longitude
            self.userCoordinate = loc.coordinate
            self.onLocationUpdate?(loc)
            self.fetchAddress(for: loc)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.state = .failure(error: "فشل تحديث الموقع: \(error.localizedDescription)")
        }
    }
}
