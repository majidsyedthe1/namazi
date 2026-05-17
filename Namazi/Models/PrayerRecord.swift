import Foundation
import SwiftData

@Model
final class PrayerRecord {
    var id: UUID = UUID()
    var userId: UUID = UUID()

    var prayerName: String = ""
    var prayerDate: Date = Date()

    var category: String = PrayerCategory.fard.rawValue
    var specialType: String?

    var windowStart: Date?
    var windowEnd: Date?

    var loggedAt: Date = Date()
    var startedAt: Date?
    var endedAt: Date?
    var durationSeconds: Int?

    var status: String = PrayerStatus.onTime.rawValue
    var isOnTime: Bool = true
    var userOverrodeStatus: Bool = false

    var source: String = PrayerSource.manual.rawValue
    var rakats: Int = 4

    var isTravelling: Bool = false
    var isQada: Bool = false
    var qadaForDate: Date?

    var prayedInJamaat: Bool = false
    var locationType: String = LocationType.home.rawValue

    var latitude: Double?
    var longitude: Double?
    var timezone: String?

    var notes: String?
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \RakatRecord.prayerRecord)
    var rakatRecords: [RakatRecord]? = []

    @Relationship(deleteRule: .cascade, inverse: \PostureEvent.prayerRecord)
    var postureEvents: [PostureEvent]? = []

    init(
        id: UUID = UUID(),
        userId: UUID,
        prayerName: PrayerName,
        prayerDate: Date,
        category: PrayerCategory = .fard,
        specialType: SpecialPrayerType? = nil,
        windowStart: Date? = nil,
        windowEnd: Date? = nil,
        loggedAt: Date = Date(),
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        durationSeconds: Int? = nil,
        status: PrayerStatus,
        isOnTime: Bool,
        userOverrodeStatus: Bool = false,
        source: PrayerSource,
        rakats: Int,
        isTravelling: Bool = false,
        isQada: Bool = false,
        qadaForDate: Date? = nil,
        prayedInJamaat: Bool = false,
        locationType: LocationType = .home,
        latitude: Double? = nil,
        longitude: Double? = nil,
        timezone: String? = nil,
        notes: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.prayerName = prayerName.rawValue
        self.prayerDate = prayerDate
        self.category = category.rawValue
        self.specialType = specialType?.rawValue
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.loggedAt = loggedAt
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.status = status.rawValue
        self.isOnTime = isOnTime
        self.userOverrodeStatus = userOverrodeStatus
        self.source = source.rawValue
        self.rakats = rakats
        self.isTravelling = isTravelling
        self.isQada = isQada
        self.qadaForDate = qadaForDate
        self.prayedInJamaat = prayedInJamaat
        self.locationType = locationType.rawValue
        self.latitude = latitude
        self.longitude = longitude
        self.timezone = timezone
        self.notes = notes
        self.updatedAt = updatedAt
    }
}

extension PrayerRecord {
    var prayer: PrayerName {
        get { PrayerName(rawValue: prayerName) ?? .fajr }
        set { prayerName = newValue.rawValue }
    }

    var prayerCategory: PrayerCategory {
        get { PrayerCategory(rawValue: category) ?? .fard }
        set { category = newValue.rawValue }
    }

    var prayerStatus: PrayerStatus {
        get { PrayerStatus(rawValue: status) ?? .onTime }
        set { status = newValue.rawValue }
    }

    var prayerSource: PrayerSource {
        get { PrayerSource(rawValue: source) ?? .manual }
        set { source = newValue.rawValue }
    }

    var location: LocationType {
        get { LocationType(rawValue: locationType) ?? .home }
        set { locationType = newValue.rawValue }
    }

    var special: SpecialPrayerType? {
        get { specialType.flatMap(SpecialPrayerType.init(rawValue:)) }
        set { specialType = newValue?.rawValue }
    }
}
