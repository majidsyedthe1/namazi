import Foundation
import SwiftData

// Progress is always derived from PrayerRecord at query time — never stored here.
// This keeps progress accurate after iCloud merges without re-computing on every device.

@Model
final class Goal {
    var id: UUID = UUID()
    var userId: UUID = UUID()

    /// "all" (any prayer) or a specific PrayerName raw value.
    var prayerName: String = "all"
    var metric: String = GoalMetric.completed.rawValue
    var targetValue: Int = 0
    var period: String = GoalPeriod.daily.rawValue

    var startDate: Date = Date()
    /// Null for rolling-period goals (e.g. "weekly forever").
    var endDate: Date?

    var isActive: Bool = true
    var isCompleted: Bool = false
    var completedDate: Date?

    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        userId: UUID,
        prayerName: String = "all",
        metric: GoalMetric,
        targetValue: Int,
        period: GoalPeriod,
        startDate: Date,
        endDate: Date? = nil,
        isActive: Bool = true,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.prayerName = prayerName
        self.metric = metric.rawValue
        self.targetValue = targetValue
        self.period = period.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.createdAt = createdAt
    }
}

extension Goal {
    var metricValue: GoalMetric {
        get { GoalMetric(rawValue: metric) ?? .completed }
        set { metric = newValue.rawValue }
    }

    var periodValue: GoalPeriod {
        get { GoalPeriod(rawValue: period) ?? .daily }
        set { period = newValue.rawValue }
    }
}
