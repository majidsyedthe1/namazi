import Foundation
import SwiftData

// Deterministic mock data builder.
//
// Generates 12 months of realistic prayer history ending on `anchor` (default: today).
// Uses a seeded RNG so the same data is produced on every run — safe for previews and
// snapshot testing. Insert everything into a ModelContext (typically the in-memory
// preview container).
//
// Coverage: on time / late / missed / Qada / Jumuah / travel week / Watch + manual
// sources / posture events / surah recitations / per-prayer stats / goals.

enum MockDataGenerator {

    // MARK: - Public entry point

    static func populate(
        _ context: ModelContext,
        anchor today: Date = Date(),
        seed: UInt64 = 0xC0FFEEDEADBEEF
    ) {
        var rng = SeededRNG(seed: seed)
        let userId = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let cal = Calendar.namaziGregorian
        let startOfToday = cal.startOfDay(for: today)
        guard let startDate = cal.date(byAdding: .day, value: -364, to: startOfToday) else { return }

        // Settings — singleton row
        let settings = UserSettings(
            userId: userId,
            calculationMethod: .ISNA,
            madhab: .Hanafi,
            isTravelMode: false,
            highLatitudeMode: false,
            latitude: 40.7128,
            longitude: -74.0060,
            timezone: "America/New_York",
            city: "New York",
            country: "United States",
            locationAutoDetect: true
        )
        context.insert(settings)

        // Notification preferences — 5 rows
        for prayer in PrayerName.fiveDaily {
            let pref = NotificationPreference(
                userId: userId,
                prayerName: prayer,
                enabled: true,
                timing: prayer == .fajr ? .minutesBeforeEnd : .atStart,
                minutesOffset: prayer == .fajr ? 10 : 0,
                soundEnabled: true,
                adhanSound: prayer == .fajr ? .makkah : .madinah
            )
            context.insert(pref)
        }

        // Pick a travel week somewhere in the middle of the year
        let travelStart = cal.date(byAdding: .day, value: -200, to: startOfToday)!
        let travelEnd = cal.date(byAdding: .day, value: -193, to: startOfToday)!

        // Records accumulator (for stats pass at the end)
        var allRecords: [PrayerRecord] = []
        var missedPool: [(date: Date, prayer: PrayerName, idx: Int)] = []

        // Walk day by day
        for offset in 0...364 {
            let day = cal.date(byAdding: .day, value: offset, to: startDate)!
            let dayOfYear = cal.ordinality(of: .day, in: .year, for: day) ?? 1
            let weekday = cal.component(.weekday, from: day) // 1 = Sunday, 6 = Friday
            let isFriday = (weekday == 6)
            let isTravelDay = day >= travelStart && day < travelEnd

            // Daily completion trend: 0.62 (oldest) → 0.88 (newest)
            let progress = Double(offset) / 364.0
            let baseCompletion = 0.62 + (0.88 - 0.62) * progress

            // Today's prayer list
            let prayers: [PrayerName] = isFriday
                ? [.fajr, .jumuah, .asr, .maghrib, .isha]
                : PrayerName.fiveDaily

            for prayer in prayers {
                let windows = PrayerWindowCalculator.windows(for: day, dayOfYear: dayOfYear)
                guard let window = windows[prayer] else { continue }

                let prayerMultiplier = perPrayerMultiplier(prayer)
                let completionChance = min(0.96, baseCompletion * prayerMultiplier)
                let didPray = rng.uniform() < completionChance

                if !didPray {
                    // Missed — record with status .missed, no startedAt/endedAt
                    let record = PrayerRecord(
                        userId: userId,
                        prayerName: prayer,
                        prayerDate: day,
                        category: .fard,
                        specialType: prayer == .jumuah ? .jumuah : nil,
                        windowStart: window.start,
                        windowEnd: window.end,
                        loggedAt: window.end.addingTimeInterval(60 * 60 * 6), // logged later as missed
                        startedAt: nil,
                        endedAt: nil,
                        durationSeconds: nil,
                        status: .missed,
                        isOnTime: false,
                        source: .manual,
                        rakats: rakatCount(for: prayer, travelling: isTravelDay),
                        isTravelling: isTravelDay,
                        locationType: .home,
                        latitude: 40.7128,
                        longitude: -74.0060,
                        timezone: "America/New_York"
                    )
                    context.insert(record)
                    allRecords.append(record)
                    // Eligible for Qada conversion (only for prayers > 30 days ago so it's "made up later")
                    if offset < 365 - 30 {
                        missedPool.append((day, prayer, allRecords.count - 1))
                    }
                    continue
                }

                // Completed — was it on time?
                let onTimeChance = 0.80
                let isOnTime = rng.uniform() < onTimeChance
                let status: PrayerStatus = isOnTime ? .onTime : .late

                // Started timing
                let startedAt: Date
                if isOnTime {
                    // Anywhere from window start to 80% of window
                    let windowDur = window.end.timeIntervalSince(window.start)
                    startedAt = window.start.addingTimeInterval(rng.uniform() * windowDur * 0.8)
                } else {
                    // After window end but before next window (cap at +90 min)
                    startedAt = window.end.addingTimeInterval(rng.uniform() * 90 * 60 + 5 * 60)
                }

                let duration = prayerDuration(prayer, rng: &rng)
                let endedAt = startedAt.addingTimeInterval(TimeInterval(duration))

                // Jamaat — biased by prayer
                let inJamaat = rng.uniform() < jamaatChance(for: prayer)

                // Location
                let location = locationFor(prayer: prayer, inJamaat: inJamaat, travelling: isTravelDay, rng: &rng)

                // Source — Watch only for the last 180 days
                let useWatch = (364 - offset) <= 180 && rng.uniform() < 0.85
                let source: PrayerSource = useWatch ? .watch : .manual

                let rakats = rakatCount(for: prayer, travelling: isTravelDay)

                let record = PrayerRecord(
                    userId: userId,
                    prayerName: prayer,
                    prayerDate: day,
                    category: .fard,
                    specialType: prayer == .jumuah ? .jumuah : nil,
                    windowStart: window.start,
                    windowEnd: window.end,
                    loggedAt: endedAt.addingTimeInterval(TimeInterval(Int(rng.uniform() * 120))),
                    startedAt: source == .watch ? startedAt : nil,
                    endedAt: source == .watch ? endedAt : nil,
                    durationSeconds: source == .watch ? duration : nil,
                    status: status,
                    isOnTime: isOnTime,
                    source: source,
                    rakats: rakats,
                    isTravelling: isTravelDay,
                    prayedInJamaat: inJamaat,
                    locationType: location,
                    latitude: 40.7128 + (rng.uniform() - 0.5) * 0.1,
                    longitude: -74.0060 + (rng.uniform() - 0.5) * 0.1,
                    timezone: "America/New_York",
                    notes: rng.uniform() < 0.04 ? randomNote(rng: &rng) : nil
                )
                context.insert(record)

                // For Watch records, build rakats + posture events
                if source == .watch {
                    buildWatchChildren(
                        record: record,
                        rakats: rakats,
                        prayerStart: startedAt,
                        totalDuration: duration,
                        context: context,
                        rng: &rng
                    )
                }

                allRecords.append(record)
            }
        }

        // Convert ~8 missed prayers to Qada (makeup) — same record is updated:
        //   status -> qada, loggedAt becomes later, qadaForDate = original date
        let qadaCount = min(8, missedPool.count)
        var qadaIndices = Set<Int>()
        while qadaIndices.count < qadaCount {
            qadaIndices.insert(Int(rng.next() % UInt64(missedPool.count)))
        }
        for idx in qadaIndices {
            let entry = missedPool[idx]
            let r = allRecords[entry.idx]
            r.prayerStatus = .qada
            r.isQada = true
            r.qadaForDate = entry.date
            // Logged some days later (within 14 days)
            let daysLater = Int(rng.uniform() * 14) + 1
            r.loggedAt = cal.date(byAdding: .day, value: daysLater, to: entry.date)!
            r.updatedAt = r.loggedAt
        }

        // Build per-prayer stats (overall + 5 prayers)
        rebuildStats(records: allRecords, userId: userId, context: context, today: startOfToday)

        // A few goals
        seedGoals(userId: userId, context: context, today: startOfToday)
    }

    // MARK: - Helpers: per-prayer biases

    private static func perPrayerMultiplier(_ prayer: PrayerName) -> Double {
        switch prayer {
        case .fajr: return 0.72       // hardest
        case .dhuhr: return 1.04
        case .asr: return 1.00
        case .maghrib: return 1.06
        case .isha: return 0.95
        case .jumuah: return 1.08
        default: return 1.0
        }
    }

    private static func jamaatChance(for prayer: PrayerName) -> Double {
        switch prayer {
        case .fajr: return 0.18
        case .dhuhr: return 0.22
        case .asr: return 0.18
        case .maghrib: return 0.40
        case .isha: return 0.45
        case .jumuah: return 0.95
        default: return 0.20
        }
    }

    private static func rakatCount(for prayer: PrayerName, travelling: Bool) -> Int {
        if travelling {
            switch prayer {
            case .dhuhr, .asr, .isha: return 2
            default: break
            }
        }
        switch prayer {
        case .fajr, .jumuah: return 2
        case .maghrib: return 3
        case .dhuhr, .asr, .isha: return 4
        default: return 4
        }
    }

    private static func prayerDuration(_ prayer: PrayerName, rng: inout SeededRNG) -> Int {
        // base seconds + jitter
        let (base, jitter): (Int, Int)
        switch prayer {
        case .fajr: (base, jitter) = (260, 90)
        case .dhuhr: (base, jitter) = (310, 110)
        case .asr: (base, jitter) = (290, 100)
        case .maghrib: (base, jitter) = (230, 80)
        case .isha: (base, jitter) = (370, 110)
        case .jumuah: (base, jitter) = (900, 360) // includes khutbah
        default: (base, jitter) = (300, 100)
        }
        return base + Int(rng.uniform() * Double(jitter))
    }

    private static func locationFor(
        prayer: PrayerName,
        inJamaat: Bool,
        travelling: Bool,
        rng: inout SeededRNG
    ) -> LocationType {
        if travelling { return .travel }
        if inJamaat {
            // Mostly masjid; small chance of work jamaat
            return rng.uniform() < 0.85 ? .masjid : .work
        }
        switch prayer {
        case .dhuhr, .asr: return rng.uniform() < 0.55 ? .work : .home
        default: return .home
        }
    }

    private static func randomNote(rng: inout SeededRNG) -> String {
        let notes = [
            "Felt focused alhamdulillah",
            "Prayed Surah Al-Mulk",
            "Long sajda today",
            "Combined with travelling",
            "Caught the iqama just in time",
            "Recited slowly",
            "Quiet evening prayer"
        ]
        return notes[Int(rng.next() % UInt64(notes.count))]
    }

    // MARK: - Watch-source children (rakats, postures, surahs)

    private static func buildWatchChildren(
        record: PrayerRecord,
        rakats: Int,
        prayerStart: Date,
        totalDuration: Int,
        context: ModelContext,
        rng: inout SeededRNG
    ) {
        var cursor = prayerStart
        let avgPerRakat = totalDuration / max(rakats, 1)

        for n in 1...rakats {
            // First rakat slightly longer, last rakat includes tashahhud
            let isFirst = (n == 1)
            let isLast = (n == rakats)
            let isMiddle = (rakats >= 3 && n == 2) // 3/4-rakat prayers: tashahhud after rakat 2

            // Posture sequence: qiyam → ruku → sajda → jalsa → sajda → (tashahhud)
            let qiyamLen = (isFirst ? 60 : 30) + Int(rng.uniform() * 40)
            let rukuLen = 6 + Int(rng.uniform() * 5)
            let sajda1Len = 7 + Int(rng.uniform() * 5)
            let jalsaLen = 3 + Int(rng.uniform() * 3)
            let sajda2Len = 7 + Int(rng.uniform() * 5)
            let tashahhudLen = (isLast ? 50 : 0) + (isMiddle ? 25 : 0) + Int(rng.uniform() * 15)

            let rakatDuration =
                qiyamLen + rukuLen + sajda1Len + jalsaLen + sajda2Len + tashahhudLen

            // Cap so total stays near totalDuration (cheap normalization)
            let cappedDuration = min(rakatDuration, avgPerRakat * 2)

            let rakat = RakatRecord(
                rakahNumber: n,
                type: .fard,
                startedAt: cursor,
                durationSeconds: cappedDuration
            )
            rakat.prayerRecord = record
            context.insert(rakat)

            // Posture events
            var pCursor = cursor
            insertPosture(.qiyam, duration: qiyamLen, pitch: 5 + rng.uniform() * 10,
                          start: &pCursor, rakat: rakat, record: record,
                          rakahNumber: n, context: context)
            insertPosture(.ruku, duration: rukuLen, pitch: 85 + rng.uniform() * 10,
                          start: &pCursor, rakat: rakat, record: record,
                          rakahNumber: n, context: context)
            insertPosture(.sajda, duration: sajda1Len, pitch: 150 + rng.uniform() * 20,
                          start: &pCursor, rakat: rakat, record: record,
                          rakahNumber: n, context: context)
            insertPosture(.jalsa, duration: jalsaLen, pitch: 120 + rng.uniform() * 10,
                          start: &pCursor, rakat: rakat, record: record,
                          rakahNumber: n, context: context)
            insertPosture(.sajda, duration: sajda2Len, pitch: 150 + rng.uniform() * 20,
                          start: &pCursor, rakat: rakat, record: record,
                          rakahNumber: n, context: context)
            if tashahhudLen > 0 {
                insertPosture(.tashahhud, duration: tashahhudLen, pitch: 120 + rng.uniform() * 10,
                              start: &pCursor, rakat: rakat, record: record,
                              rakahNumber: n, context: context)
            }

            // Surah recitations — first rakat usually has Al-Fatiha + a short surah
            if isFirst && rng.uniform() < 0.6 {
                let fatiha = SurahRecitation(
                    surahNumber: 1, surahName: "Al-Fatiha", orderInRakat: 1, isFullSurah: true
                )
                fatiha.rakatRecord = rakat
                context.insert(fatiha)

                if let short = randomShortSurah(rng: &rng) {
                    let s = SurahRecitation(
                        surahNumber: short.number,
                        surahName: short.name,
                        orderInRakat: 2,
                        isFullSurah: true
                    )
                    s.rakatRecord = rakat
                    context.insert(s)
                }
            }

            cursor = cursor.addingTimeInterval(TimeInterval(cappedDuration))
        }
    }

    private static func insertPosture(
        _ type: PostureType,
        duration: Int,
        pitch: Double,
        start: inout Date,
        rakat: RakatRecord,
        record: PrayerRecord,
        rakahNumber: Int,
        context: ModelContext
    ) {
        let evt = PostureEvent(
            posture: type,
            startedAt: start,
            durationSeconds: duration,
            rakahNumber: rakahNumber,
            pitchAngleDegrees: pitch,
            detectionSource: .watchAuto
        )
        evt.prayerRecord = record
        evt.rakatRecord = rakat
        context.insert(evt)
        start = start.addingTimeInterval(TimeInterval(duration))
    }

    // MARK: - Stats rebuild

    private static func rebuildStats(
        records: [PrayerRecord],
        userId: UUID,
        context: ModelContext,
        today: Date
    ) {
        let cal = Calendar.namaziGregorian
        let groups: [String: [PrayerRecord]] = Dictionary(grouping: records) { $0.prayerName }

        // Per-prayer streaks
        for prayer in PrayerName.fiveDaily {
            let rs = (groups[prayer.rawValue] ?? [])
                + (prayer == .dhuhr ? (groups[PrayerName.jumuah.rawValue] ?? []) : [])
            let stats = computeStats(records: rs, userId: userId,
                                     prayerKey: prayer.rawValue, today: today, cal: cal)
            context.insert(stats)
        }

        // Overall (all 5 daily prayed today => streak day)
        let recordsByDay: [Date: [PrayerRecord]] = Dictionary(
            grouping: records.filter { $0.prayerStatus != .missed },
            by: { cal.startOfDay(for: $0.prayerDate) }
        )
        var currentStreak = 0
        var longestStreak = 0
        var running = 0
        var lastCompleteDay: Date?
        // Walk from oldest to newest
        let sortedDays = recordsByDay.keys.sorted()
        var allCompleteDays = Set<Date>()
        for day in sortedDays {
            let rs = recordsByDay[day] ?? []
            // 5 daily prayers complete (Jumuah counts as Dhuhr)
            var seen = Set<String>()
            for r in rs {
                let name = r.prayer == .jumuah ? PrayerName.dhuhr.rawValue : r.prayerName
                seen.insert(name)
            }
            let isComplete = seen.isSuperset(of: PrayerName.fiveDaily.map { $0.rawValue })
            if isComplete {
                allCompleteDays.insert(day)
                lastCompleteDay = day
                if let prev = cal.date(byAdding: .day, value: -1, to: day),
                   allCompleteDays.contains(prev) || running == 0 {
                    running = (allCompleteDays.contains(prev) ? running : 0) + 1
                } else {
                    running = 1
                }
                longestStreak = max(longestStreak, running)
            } else {
                running = 0
            }
        }
        // Current streak — walk back from today
        var probe = today
        currentStreak = 0
        while allCompleteDays.contains(probe) {
            currentStreak += 1
            probe = cal.date(byAdding: .day, value: -1, to: probe) ?? probe
        }

        let totalCompleted = records.filter { $0.prayerStatus != .missed }.count
        let totalOnTime = records.filter { $0.prayerStatus == .onTime }.count
        let totalInJamaat = records.filter { $0.prayedInJamaat }.count
        let totalQada = records.filter { $0.prayerStatus == .qada }.count

        let overall = UserPrayerStats(
            userId: userId,
            prayerName: UserPrayerStats.overallKey,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalCompleted: totalCompleted,
            totalOnTime: totalOnTime,
            totalInJamaat: totalInJamaat,
            totalQada: totalQada,
            lastPrayedDate: lastCompleteDay,
            lastUpdated: today
        )
        context.insert(overall)
    }

    private static func computeStats(
        records: [PrayerRecord],
        userId: UUID,
        prayerKey: String,
        today: Date,
        cal: Calendar
    ) -> UserPrayerStats {
        let completed = records.filter { $0.prayerStatus != .missed }
        let prayedDays = Set(completed.map { cal.startOfDay(for: $0.prayerDate) })

        // Walk back from today to compute current streak (per prayer)
        var current = 0
        var probe = today
        while prayedDays.contains(probe) {
            current += 1
            probe = cal.date(byAdding: .day, value: -1, to: probe) ?? probe
        }

        // Longest streak — walk all days
        var longest = 0
        var run = 0
        let sortedDays = prayedDays.sorted()
        var lastDay: Date?
        for d in sortedDays {
            if let last = lastDay,
               let next = cal.date(byAdding: .day, value: 1, to: last),
               cal.isDate(next, inSameDayAs: d) {
                run += 1
            } else {
                run = 1
            }
            longest = max(longest, run)
            lastDay = d
        }

        return UserPrayerStats(
            userId: userId,
            prayerName: prayerKey,
            currentStreak: current,
            longestStreak: longest,
            totalCompleted: completed.count,
            totalOnTime: completed.filter { $0.prayerStatus == .onTime }.count,
            totalInJamaat: completed.filter { $0.prayedInJamaat }.count,
            totalQada: completed.filter { $0.prayerStatus == .qada }.count,
            lastPrayedDate: sortedDays.last,
            lastUpdated: today
        )
    }

    // MARK: - Goals

    private static func seedGoals(userId: UUID, context: ModelContext, today: Date) {
        let cal = Calendar.namaziGregorian

        let weekStart = cal.date(byAdding: .day, value: -6, to: today)!
        let monthStart = cal.date(byAdding: .day, value: -29, to: today)!
        let oldGoalStart = cal.date(byAdding: .day, value: -90, to: today)!
        let oldGoalEnd = cal.date(byAdding: .day, value: -60, to: today)!

        let active1 = Goal(
            userId: userId,
            prayerName: PrayerName.fajr.rawValue,
            metric: .completed,
            targetValue: 5,
            period: .weekly,
            startDate: weekStart,
            endDate: nil,
            isActive: true
        )
        let active2 = Goal(
            userId: userId,
            prayerName: "all",
            metric: .inJamaat,
            targetValue: 20,
            period: .monthly,
            startDate: monthStart,
            endDate: nil,
            isActive: true
        )
        let completed = Goal(
            userId: userId,
            prayerName: "all",
            metric: .streak,
            targetValue: 7,
            period: .custom,
            startDate: oldGoalStart,
            endDate: oldGoalEnd,
            isActive: false,
            isCompleted: true,
            completedDate: oldGoalEnd
        )

        context.insert(active1)
        context.insert(active2)
        context.insert(completed)
    }

    // MARK: - Surahs

    private struct SurahDef {
        let number: Int
        let name: String
        let ayahs: Int
    }

    private static let shortSurahs: [SurahDef] = [
        SurahDef(number: 112, name: "Al-Ikhlas", ayahs: 4),
        SurahDef(number: 113, name: "Al-Falaq", ayahs: 5),
        SurahDef(number: 114, name: "An-Nas", ayahs: 6),
        SurahDef(number: 108, name: "Al-Kawthar", ayahs: 3),
        SurahDef(number: 103, name: "Al-Asr", ayahs: 3),
        SurahDef(number: 109, name: "Al-Kafirun", ayahs: 6),
        SurahDef(number: 111, name: "Al-Masad", ayahs: 5),
        SurahDef(number: 106, name: "Quraysh", ayahs: 4),
        SurahDef(number: 107, name: "Al-Maun", ayahs: 7),
        SurahDef(number: 105, name: "Al-Fil", ayahs: 5),
        SurahDef(number: 110, name: "An-Nasr", ayahs: 3),
        SurahDef(number: 102, name: "At-Takathur", ayahs: 8)
    ]

    private static func randomShortSurah(rng: inout SeededRNG) -> SurahDef? {
        guard !shortSurahs.isEmpty else { return nil }
        return shortSurahs[Int(rng.next() % UInt64(shortSurahs.count))]
    }
}

// MARK: - Seeded RNG (Linear Congruential)

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed != 0 ? seed : 1 }
    mutating func next() -> UInt64 {
        state = state &* 2862933555777941757 &+ 3037000493
        return state
    }
    mutating func uniform() -> Double {
        let v = next() >> 11
        return Double(v) / Double(1 << 53)
    }
}

// MARK: - Calendar helper

extension Calendar {
    static let namaziGregorian: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        return cal
    }()
}

// MARK: - Prayer window approximator
//
// Approximate prayer start/end times for ~40°N with seasonal Fajr/Maghrib/Isha shifts.
// Real app will use Adhan-swift in Phase 3 — this is mock-only.

enum PrayerWindowCalculator {
    struct Window {
        let start: Date
        let end: Date
    }

    static func windows(for day: Date, dayOfYear: Int) -> [PrayerName: Window] {
        let cal = Calendar.namaziGregorian
        let midnight = cal.startOfDay(for: day)

        // Seasonal offset: +1 in midsummer, -1 in midwinter
        let angle = 2 * Double.pi * (Double(dayOfYear) - 172.0) / 365.0
        let s = cos(angle)

        // base minutes-since-midnight; shifted seasonally
        func at(_ baseMin: Double, shift: Double = 0) -> Date {
            let mins = baseMin - shift * s
            return midnight.addingTimeInterval(mins * 60)
        }

        let fajrStart = at(5 * 60 + 30, shift: 60)
        let fajrEnd = at(6 * 60 + 45, shift: 90)
        let dhuhrStart = at(12 * 60 + 30, shift: 15)
        let dhuhrEnd = at(15 * 60 + 30, shift: 30)
        let asrStart = at(15 * 60 + 30, shift: 30)
        let asrEnd = at(17 * 60 + 45, shift: 75)
        let maghribStart = at(17 * 60 + 45, shift: 75)
        let maghribEnd = at(18 * 60 + 30, shift: 75)
        let ishaStart = at(19 * 60 + 15, shift: 75)
        let ishaEnd = at(22 * 60 + 45, shift: 30)
        // Jumuah: replaces Dhuhr, fixed-ish window slightly after Dhuhr starts
        let jumuahStart = at(13 * 60 + 0, shift: 15)
        let jumuahEnd = at(14 * 60 + 30, shift: 15)

        return [
            .fajr: Window(start: fajrStart, end: fajrEnd),
            .dhuhr: Window(start: dhuhrStart, end: dhuhrEnd),
            .asr: Window(start: asrStart, end: asrEnd),
            .maghrib: Window(start: maghribStart, end: maghribEnd),
            .isha: Window(start: ishaStart, end: ishaEnd),
            .jumuah: Window(start: jumuahStart, end: jumuahEnd)
        ]
    }
}
