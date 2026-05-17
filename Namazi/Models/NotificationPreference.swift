import Foundation
import SwiftData

// 5 rows total per user — one per daily prayer. Never grows.

@Model
final class NotificationPreference {
    var id: UUID = UUID()
    var userId: UUID = UUID()

    var prayerName: String = ""
    /// Master on/off for this prayer.
    var enabled: Bool = true
    var timing: String = NotificationTiming.atStart.rawValue
    /// Ignored when `timing == atStart`.
    var minutesOffset: Int = 0
    /// False = silent vibration only.
    var soundEnabled: Bool = true
    /// Must be null when `soundEnabled` is false.
    var adhanSound: String?

    init(
        id: UUID = UUID(),
        userId: UUID,
        prayerName: PrayerName,
        enabled: Bool = true,
        timing: NotificationTiming = .atStart,
        minutesOffset: Int = 0,
        soundEnabled: Bool = true,
        adhanSound: AdhanSound? = nil
    ) {
        self.id = id
        self.userId = userId
        self.prayerName = prayerName.rawValue
        self.enabled = enabled
        self.timing = timing.rawValue
        self.minutesOffset = minutesOffset
        self.soundEnabled = soundEnabled
        self.adhanSound = adhanSound?.rawValue
    }
}

extension NotificationPreference {
    var prayer: PrayerName {
        get { PrayerName(rawValue: prayerName) ?? .fajr }
        set { prayerName = newValue.rawValue }
    }

    var timingValue: NotificationTiming {
        get { NotificationTiming(rawValue: timing) ?? .atStart }
        set { timing = newValue.rawValue }
    }

    var sound: AdhanSound? {
        get { adhanSound.flatMap(AdhanSound.init(rawValue:)) }
        set { adhanSound = newValue?.rawValue }
    }
}
