import SwiftUI

// Visual tokens for prayer status — mirrors the brief:
//   teal   = on time
//   amber  = late
//   red    = missed
//   purple = upcoming / active
//   qada   = teal with dashed treatment in views
//
// Keep colors in one place so we can tune the palette in one spot later.

enum PrayerStyle {
    static let onTime = Color(red: 0.16, green: 0.78, blue: 0.74)   // teal
    static let late = Color(red: 0.98, green: 0.71, blue: 0.20)     // amber
    static let missed = Color(red: 0.94, green: 0.36, blue: 0.36)   // red
    static let upcoming = Color(red: 0.58, green: 0.39, blue: 0.95) // purple
    static let pending = Color.white.opacity(0.10)                  // ring track
    static let qada = Color(red: 0.16, green: 0.78, blue: 0.74)     // teal (dashed)
    static let inJamaat = Color(red: 0.95, green: 0.83, blue: 0.42) // gold accent

    static let ringWidth: CGFloat = 16
    static let ringGap: CGFloat = 5
}

extension PrayerStatus {
    var color: Color {
        switch self {
        case .onTime: return PrayerStyle.onTime
        case .late: return PrayerStyle.late
        case .missed: return PrayerStyle.missed
        case .qada: return PrayerStyle.qada
        }
    }

    var label: String {
        switch self {
        case .onTime: return "On time"
        case .late: return "Late"
        case .missed: return "Missed"
        case .qada: return "Qada"
        }
    }
}

extension PrayerName {
    var displayName: String {
        switch self {
        case .fajr: return "Fajr"
        case .dhuhr: return "Dhuhr"
        case .asr: return "Asr"
        case .maghrib: return "Maghrib"
        case .isha: return "Isha"
        case .jumuah: return "Jumuah"
        case .eid: return "Eid"
        case .janazah: return "Janazah"
        case .tarawih: return "Tarawih"
        case .witr: return "Witr"
        }
    }

    /// SF Symbol for each prayer (rough mood, not literal).
    var symbol: String {
        switch self {
        case .fajr: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        case .jumuah: return "person.3.fill"
        default: return "star.fill"
        }
    }
}

extension PostureType {
    var displayName: String {
        switch self {
        case .qiyam: return "Qiyam"
        case .ruku: return "Ruku"
        case .sajda: return "Sajda"
        case .jalsa: return "Jalsa"
        case .tashahhud: return "Tashahhud"
        }
    }
}

// MARK: - Formatters

enum PrayerFormat {
    static let time: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    static let weekdayLong: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    static let monthShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    static func duration(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m)m" }
        return "\(m)m \(s)s"
    }

    static func relativeShort(from date: Date, to target: Date) -> String {
        let secs = Int(target.timeIntervalSince(date))
        if secs < 0 { return "now" }
        let h = secs / 3600
        let m = (secs % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}
