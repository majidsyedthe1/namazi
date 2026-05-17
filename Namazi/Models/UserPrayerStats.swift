import Foundation
import SwiftData

// 6 rows total per user — "overall" + 5 daily prayers. Never grows.
// Recalculation: fast path on new save (increment); safe path on any edit (rebuild from edit date).

@Model
final class UserPrayerStats {
    var id: UUID = UUID()
    var userId: UUID = UUID()

    /// "overall" | "Fajr" | "Dhuhr" | "Asr" | "Maghrib" | "Isha"
    var prayerName: String = "overall"

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalCompleted: Int = 0
    var totalOnTime: Int = 0
    var totalInJamaat: Int = 0
    var totalQada: Int = 0

    /// Used by the fast-path streak increment to decide "continue vs reset".
    var lastPrayedDate: Date?
    var lastUpdated: Date = Date()

    init(
        id: UUID = UUID(),
        userId: UUID,
        prayerName: String,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalCompleted: Int = 0,
        totalOnTime: Int = 0,
        totalInJamaat: Int = 0,
        totalQada: Int = 0,
        lastPrayedDate: Date? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.prayerName = prayerName
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalCompleted = totalCompleted
        self.totalOnTime = totalOnTime
        self.totalInJamaat = totalInJamaat
        self.totalQada = totalQada
        self.lastPrayedDate = lastPrayedDate
        self.lastUpdated = lastUpdated
    }

    static let overallKey = "overall"
}
