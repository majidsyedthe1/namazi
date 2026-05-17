import Foundation
import SwiftData

// Singleton — exactly 1 row per user.

@Model
final class UserSettings {
    var id: UUID = UUID()
    var userId: UUID = UUID()

    var calculationMethod: String = CalculationMethod.ISNA.rawValue
    /// Affects Asr time — Hanafi calculates Asr later than the other madhabs.
    var madhab: String = Madhab.Hanafi.rawValue

    /// Manually toggled by the user — never auto-detected.
    var isTravelMode: Bool = false
    /// Enable for Scandinavia / Canada / northern UK where Fajr–Isha can't be computed normally.
    var highLatitudeMode: Bool = false

    var latitude: Double = 0
    var longitude: Double = 0
    var timezone: String = "UTC"
    var city: String = ""
    var country: String = ""
    /// True = follow GPS; false = user has pinned the location manually.
    var locationAutoDetect: Bool = true

    var lastUpdated: Date = Date()

    init(
        id: UUID = UUID(),
        userId: UUID,
        calculationMethod: CalculationMethod = .ISNA,
        madhab: Madhab = .Hanafi,
        isTravelMode: Bool = false,
        highLatitudeMode: Bool = false,
        latitude: Double,
        longitude: Double,
        timezone: String,
        city: String,
        country: String,
        locationAutoDetect: Bool = true,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.calculationMethod = calculationMethod.rawValue
        self.madhab = madhab.rawValue
        self.isTravelMode = isTravelMode
        self.highLatitudeMode = highLatitudeMode
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone
        self.city = city
        self.country = country
        self.locationAutoDetect = locationAutoDetect
        self.lastUpdated = lastUpdated
    }
}

extension UserSettings {
    var method: CalculationMethod {
        get { CalculationMethod(rawValue: calculationMethod) ?? .ISNA }
        set { calculationMethod = newValue.rawValue }
    }

    var madhabValue: Madhab {
        get { Madhab(rawValue: madhab) ?? .Hanafi }
        set { madhab = newValue.rawValue }
    }
}
