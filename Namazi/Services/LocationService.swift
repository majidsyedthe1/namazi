import Foundation
import CoreLocation
import Observation

// Thin wrapper around CLLocationManager.
//
// Responsibilities:
//   - Track authorization status (notDetermined / denied / authorized)
//   - Request "when in use" permission on demand
//   - Fetch one location fix and publish it as an Equatable `LocationFix`
//
// Equatable LocationFix is published (not CLLocation) so SwiftUI's `onChange`
// works without bridging NSObject equality.

/// Snapshot of a location reading suitable for SwiftUI observation.
struct LocationFix: Equatable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

@Observable
final class LocationService: NSObject {
    enum AuthState {
        case notDetermined
        case denied
        case authorized
    }

    var authState: AuthState = .notDetermined
    var lastFix: LocationFix?
    var lastError: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        // Prayer times don't need sub-meter accuracy; this gets a fix faster
        // and uses far less battery than `kCLLocationAccuracyBest`.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        syncAuthState()
    }

    /// Trigger the system permission prompt (no-op if already determined).
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Ask for a single location reading. Caller should ensure authorization first.
    func requestLocation() {
        guard authState == .authorized else { return }
        manager.requestLocation()
    }

    private func syncAuthState() {
        switch manager.authorizationStatus {
        case .notDetermined:
            authState = .notDetermined
        case .restricted, .denied:
            authState = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            authState = .authorized
        @unknown default:
            authState = .notDetermined
        }
    }
}

extension LocationService {
    /// Reverse-geocode a fix into a placemark (city, country, timezone, …).
    /// Returns nil if the geocoder fails (e.g. offline).
    func reverseGeocode(_ fix: LocationFix) async -> CLPlacemark? {
        let location = CLLocation(latitude: fix.latitude, longitude: fix.longitude)
        let geocoder = CLGeocoder()
        return try? await geocoder.reverseGeocodeLocation(location).first
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        syncAuthState()
        // As soon as we have authorization, fetch one fix automatically.
        if authState == .authorized {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        lastFix = LocationFix(
            latitude: loc.coordinate.latitude,
            longitude: loc.coordinate.longitude,
            timestamp: loc.timestamp
        )
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = error.localizedDescription
    }
}
