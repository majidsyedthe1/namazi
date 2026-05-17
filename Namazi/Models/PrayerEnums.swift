import Foundation

// All enums are stored as `String` raw values on the SwiftData models for
// CloudKit compatibility. The model fields are plain `String`; these enums
// provide typed get/set via computed properties on each model.

enum PrayerName: String, Codable, CaseIterable, Identifiable {
    case fajr = "Fajr"
    case dhuhr = "Dhuhr"
    case asr = "Asr"
    case maghrib = "Maghrib"
    case isha = "Isha"
    case jumuah = "Jumuah"
    case eid = "Eid"
    case janazah = "Janazah"
    case tarawih = "Tarawih"
    case witr = "Witr"

    var id: String { rawValue }

    static let fiveDaily: [PrayerName] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
}

enum PrayerCategory: String, Codable, CaseIterable {
    case fard
    case sunnah
    case nawafil
}

enum SpecialPrayerType: String, Codable, CaseIterable {
    case jumuah
    case eid
    case janazah
    case shukrana
    case tarawih
    case other
}

enum PrayerStatus: String, Codable, CaseIterable {
    case onTime
    case late
    case missed
    case qada
}

enum PrayerSource: String, Codable, CaseIterable {
    case watch
    case manual
}

enum LocationType: String, Codable, CaseIterable {
    case home
    case masjid
    case work
    case travel
    case other
}

enum RakatType: String, Codable, CaseIterable {
    case fard
    case sunnah
    case witr
}

// v1 postures only. `itidal` and `tasleem` are deferred — too brief / hard to detect reliably.
enum PostureType: String, Codable, CaseIterable {
    case qiyam
    case ruku
    case sajda
    case jalsa
    case tashahhud
}

enum PostureDetectionSource: String, Codable, CaseIterable {
    case watchAuto = "watch_auto"
    case watchManual = "watch_manual"
}

enum CalculationMethod: String, Codable, CaseIterable {
    case ISNA
    case MWL
    case Hanafi
    case Egyptian
    case Karachi
}

enum Madhab: String, Codable, CaseIterable {
    case Hanafi
    case Shafi
    case Maliki
    case Hanbali
}

enum NotificationTiming: String, Codable, CaseIterable {
    case atStart
    case minutesAfterStart
    case minutesBeforeEnd
}

enum AdhanSound: String, Codable, CaseIterable {
    case makkah
    case madinah
    case defaultSound = "default"
}

enum GoalMetric: String, Codable, CaseIterable {
    case completed
    case onTime
    case inJamaat
    case streak
    case qada
}

enum GoalPeriod: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case custom
}
