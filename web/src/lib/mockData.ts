// JS port of Namazi/Mock/MockDataGenerator.swift
// Produces identical data shape for the same seed, so iOS previews and
// the web prototype tell the same story.

import { getPrayerWindows } from './prayerTimes'
import type {
  PrayerRecord, UserSettings, UserPrayerStats,
  Goal, NotificationPreference, PrayerWindow,
} from '../types'
import { FIVE_DAILY } from '../types'

// ── Seeded RNG (port of SeededRNG in MockDataGenerator.swift) ────────────────
// Uses BigInt to replicate Swift's UInt64 overflow arithmetic exactly.
class SeededRNG {
  private state: bigint
  constructor(seed: bigint = 0xC0FFEEDEADBEEFn) {
    this.state = seed !== 0n ? seed : 1n
  }
  private next(): bigint {
    const MASK = (1n << 64n) - 1n
    this.state = (this.state * 2862933555777941757n + 3037000493n) & MASK
    return this.state
  }
  uniform(): number {
    return Number(this.next() >> 11n) / 2 ** 53
  }
  bool(probability: number): boolean {
    return this.uniform() < probability
  }
  intBetween(lo: number, hi: number): number {
    return lo + Math.floor(this.uniform() * (hi - lo + 1))
  }
  pick<T>(arr: T[]): T {
    return arr[Math.floor(this.uniform() * arr.length)]
  }
}

// ── Constants matching MockDataGenerator.swift ───────────────────────────────
const MOCK_USER_ID = '00000000-0000-0000-0000-000000000001'
const MOCK_LAT     = 40.7128
const MOCK_LNG     = -74.0060
const MOCK_CITY    = 'New York'
const MOCK_COUNTRY = 'United States'
const MOCK_TZ      = 'America/New_York'

const PRAYER_COMPLETION_MULT: Record<string, number> = {
  Fajr: 0.72, Dhuhr: 1.04, Asr: 1.00, Maghrib: 1.06, Isha: 0.95, Jumuah: 1.08,
}
const JAMAAT_RATE: Record<string, number> = {
  Fajr: 0.18, Dhuhr: 0.22, Asr: 0.18, Maghrib: 0.40, Isha: 0.45, Jumuah: 0.95,
}
const BASE_DURATION: Record<string, number> = {
  Fajr: 260, Dhuhr: 310, Asr: 290, Maghrib: 230, Isha: 370, Jumuah: 900,
}
const DURATION_JITTER: Record<string, number> = {
  Fajr: 90, Dhuhr: 110, Asr: 100, Maghrib: 80, Isha: 110, Jumuah: 360,
}

function uuid(rng: SeededRNG): string {
  const hex = (n: number) => n.toString(16).padStart(2, '0')
  const b = Array.from({ length: 16 }, () => rng.intBetween(0, 255))
  b[6] = (b[6] & 0x0f) | 0x40
  b[8] = (b[8] & 0x3f) | 0x80
  return `${hex(b[0])}${hex(b[1])}${hex(b[2])}${hex(b[3])}-${hex(b[4])}${hex(b[5])}-${hex(b[6])}${hex(b[7])}-${hex(b[8])}${hex(b[9])}-${hex(b[10])}${hex(b[11])}${hex(b[12])}${hex(b[13])}${hex(b[14])}${hex(b[15])}`
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10)
}

// ── Main generator ───────────────────────────────────────────────────────────
export interface MockDataSet {
  settings: UserSettings
  records: PrayerRecord[]
  stats: UserPrayerStats[]
  goals: Goal[]
  notifications: NotificationPreference[]
}

export function generateMockData(anchor: Date = new Date()): MockDataSet {
  const rng = new SeededRNG()

  // Build prayer windows for every day using adhan (real calculations)
  const windowsCache = new Map<string, PrayerWindow[]>()
  function getWindows(date: Date): PrayerWindow[] {
    const key = isoDate(date)
    if (!windowsCache.has(key)) {
      windowsCache.set(key, getPrayerWindows(MOCK_LAT, MOCK_LNG, date, 'ISNA', 'Hanafi'))
    }
    return windowsCache.get(key)!
  }

  const records: PrayerRecord[] = []
  const missedRecords: PrayerRecord[] = []

  // Travel week: days -200 to -193 before anchor
  const travelStart = new Date(anchor); travelStart.setDate(anchor.getDate() - 200)
  const travelEnd   = new Date(anchor); travelEnd.setDate(anchor.getDate() - 193)

  const watchCutoff = new Date(anchor); watchCutoff.setDate(anchor.getDate() - 180)

  for (let dayOffset = 0; dayOffset < 365; dayOffset++) {
    const date = new Date(anchor)
    date.setDate(anchor.getDate() - 364 + dayOffset)
    date.setHours(0, 0, 0, 0)

    const baseCompletion = 0.62 + (0.88 - 0.62) * (dayOffset / 364)
    const isFriday = date.getDay() === 5
    const isTravelling = date >= travelStart && date <= travelEnd
    const isWatchSource = date >= watchCutoff && rng.bool(0.85)

    const windows = getWindows(date)

    for (const w of windows) {
      const name = w.name
      const mult = PRAYER_COMPLETION_MULT[name] ?? 1
      const prob = Math.min(baseCompletion * mult, 0.97)

      if (!rng.bool(prob)) {
        // Missed prayer
        const loggedAt = new Date(w.end.getTime() + 6 * 3600 * 1000)
        const rec: PrayerRecord = {
          id: uuid(rng),
          userId: MOCK_USER_ID,
          prayerName: name,
          prayerDate: isoDate(date),
          category: 'fard',
          specialType: name === 'Jumuah' ? 'jumuah' : null,
          windowStart: w.start.toISOString(),
          windowEnd:   w.end.toISOString(),
          loggedAt:    loggedAt.toISOString(),
          startedAt: null, endedAt: null, durationSeconds: null,
          status: 'missed',
          isOnTime: false,
          userOverrodeStatus: false,
          source: 'manual',
          rakats: isFriday && name === 'Jumuah' ? 2 : defaultRakats(name, isTravelling),
          isTravelling,
          isQada: false, qadaForDate: null,
          prayedInJamaat: false,
          locationType: isTravelling ? 'travel' : 'home',
          latitude: MOCK_LAT + (rng.uniform() - 0.5) * 0.1,
          longitude: MOCK_LNG + (rng.uniform() - 0.5) * 0.1,
          timezone: MOCK_TZ,
          notes: null,
          updatedAt: loggedAt.toISOString(),
        }
        records.push(rec)
        // Only eligible for qada if missed >30 days ago
        if (dayOffset < 335) missedRecords.push(rec)
        continue
      }

      const onTime = rng.bool(0.80)
      let startedAt: Date

      if (onTime) {
        const windowLen = w.end.getTime() - w.start.getTime()
        startedAt = new Date(w.start.getTime() + rng.uniform() * windowLen * 0.8)
      } else {
        startedAt = new Date(w.end.getTime() + rng.intBetween(5, 95) * 60 * 1000)
      }

      const baseDur = BASE_DURATION[name] ?? 300
      const jitter  = DURATION_JITTER[name] ?? 100
      const durationSeconds = baseDur + Math.floor((rng.uniform() * 2 - 1) * jitter)
      const endedAt = new Date(startedAt.getTime() + durationSeconds * 1000)
      const loggedAt = new Date(endedAt.getTime() + rng.intBetween(10, 120) * 1000)

      const jamRate = JAMAAT_RATE[name] ?? 0.25
      const prayedInJamaat = rng.bool(jamRate)
      const locationType = resolveLocation(name, isTravelling, prayedInJamaat, rng)

      const notes = rng.bool(0.04) ? rng.pick([
        'Felt focused alhamdulillah',
        'Prayed Surah Al-Mulk',
        'Long sajda today',
        'Combined with travelling',
        'Caught the iqama just in time',
        'Recited slowly',
        'Quiet evening prayer',
      ]) : null

      records.push({
        id: uuid(rng),
        userId: MOCK_USER_ID,
        prayerName: name,
        prayerDate: isoDate(date),
        category: 'fard',
        specialType: name === 'Jumuah' ? 'jumuah' : null,
        windowStart: w.start.toISOString(),
        windowEnd:   w.end.toISOString(),
        loggedAt:    loggedAt.toISOString(),
        startedAt:   isWatchSource ? startedAt.toISOString() : null,
        endedAt:     isWatchSource ? endedAt.toISOString()   : null,
        durationSeconds: isWatchSource ? durationSeconds : null,
        status: onTime ? 'onTime' : 'late',
        isOnTime: onTime,
        userOverrodeStatus: false,
        source: isWatchSource ? 'watch' : 'manual',
        rakats: defaultRakats(name, isTravelling),
        isTravelling,
        isQada: false, qadaForDate: null,
        prayedInJamaat,
        locationType,
        latitude:  MOCK_LAT + (rng.uniform() - 0.5) * 0.1,
        longitude: MOCK_LNG + (rng.uniform() - 0.5) * 0.1,
        timezone: MOCK_TZ,
        notes,
        updatedAt: loggedAt.toISOString(),
      })
    }
  }

  // Convert ~8 missed prayers to Qada
  const qdaCandidates = [...missedRecords].sort(() => rng.uniform() - 0.5).slice(0, 8)
  for (const rec of qdaCandidates) {
    rec.isQada = true
    rec.status = 'qada'
    rec.qadaForDate = rec.prayerDate
    const originalDate = new Date(rec.prayerDate)
    const daysLater = rng.intBetween(1, 14)
    const qdaDate = new Date(originalDate)
    qdaDate.setDate(originalDate.getDate() + daysLater)
    rec.loggedAt = qdaDate.toISOString()
    rec.updatedAt = qdaDate.toISOString()
  }

  return {
    settings: buildSettings(),
    records,
    stats: buildStats(records, anchor),
    goals: buildGoals(rng, anchor),
    notifications: buildNotifications(),
  }
}

function defaultRakats(name: string, travelling: boolean): number {
  if (travelling) {
    const t: Record<string, number> = { Fajr: 2, Dhuhr: 2, Asr: 2, Maghrib: 3, Isha: 2 }
    return t[name] ?? 4
  }
  const n: Record<string, number> = { Fajr: 2, Dhuhr: 4, Asr: 4, Maghrib: 3, Isha: 4, Jumuah: 2, Witr: 3 }
  return n[name] ?? 4
}

function resolveLocation(
  name: string, travelling: boolean, jamaat: boolean, rng: SeededRNG,
): PrayerRecord['locationType'] {
  if (travelling) return 'travel'
  if (jamaat) return rng.bool(0.85) ? 'masjid' : 'work'
  if (name === 'Dhuhr' || name === 'Asr') return rng.bool(0.55) ? 'work' : 'home'
  return 'home'
}

function buildSettings(): UserSettings {
  return {
    id: uuid(new SeededRNG(1n)),
    userId: MOCK_USER_ID,
    calculationMethod: 'ISNA',
    madhab: 'Hanafi',
    isTravelMode: false,
    highLatitudeMode: false,
    latitude: MOCK_LAT,
    longitude: MOCK_LNG,
    timezone: MOCK_TZ,
    city: MOCK_CITY,
    country: MOCK_COUNTRY,
    locationAutoDetect: true,
    lastUpdated: new Date().toISOString(),
  }
}

function buildStats(records: PrayerRecord[], anchor: Date): UserPrayerStats[] {
  const now = new Date(anchor); now.setHours(23, 59, 59)
  const stats: UserPrayerStats[] = []

  for (const pname of [...FIVE_DAILY, 'overall'] as string[]) {
    const isOverall = pname === 'overall'
    const relevant = isOverall
      ? records.filter(r => FIVE_DAILY.includes(r.prayerName))
      : records.filter(r => r.prayerName === pname)

    const completed = relevant.filter(r => r.status !== 'missed')
    const onTime    = relevant.filter(r => r.isOnTime)
    const inJamaat  = relevant.filter(r => r.prayedInJamaat)
    const qada      = relevant.filter(r => r.isQada)

    // Streak calculation: walk backward from today
    let currentStreak = 0, longestStreak = 0, streak = 0
    const daySet = new Set<string>()

    if (isOverall) {
      // A day counts if all 5 prayers were logged (not missed)
      const byDay = new Map<string, number>()
      for (const r of relevant.filter(r => r.status !== 'missed')) {
        byDay.set(r.prayerDate, (byDay.get(r.prayerDate) ?? 0) + 1)
      }
      for (const [day, count] of byDay) {
        if (count >= 5) daySet.add(day)
      }
    } else {
      for (const r of completed) daySet.add(r.prayerDate)
    }

    const check = new Date(anchor)
    check.setHours(0, 0, 0, 0)
    // Don't penalise today if not yet done
    if (!daySet.has(isoDate(check))) check.setDate(check.getDate() - 1)

    while (true) {
      if (daySet.has(isoDate(check))) {
        streak++
        longestStreak = Math.max(longestStreak, streak)
        if (currentStreak === 0 && streak > 0) currentStreak = streak
        check.setDate(check.getDate() - 1)
      } else {
        if (currentStreak === 0) currentStreak = streak
        streak = 0
        check.setDate(check.getDate() - 1)
        if (check < new Date(anchor.getTime() - 365 * 86400 * 1000)) break
      }
    }
    longestStreak = Math.max(longestStreak, streak)
    if (currentStreak === 0) currentStreak = streak

    const lastPrayed = completed.reduce((best, r) =>
      !best || r.prayerDate > best ? r.prayerDate : best, null as string | null)

    stats.push({
      id: `stats-${pname}`,
      userId: MOCK_USER_ID,
      prayerName: pname,
      currentStreak,
      longestStreak,
      totalCompleted: completed.length,
      totalOnTime:    onTime.length,
      totalInJamaat:  inJamaat.length,
      totalQada:      qada.length,
      lastPrayedDate: lastPrayed,
      lastUpdated: new Date().toISOString(),
    })
  }
  return stats
}

function buildGoals(rng: SeededRNG, anchor: Date): Goal[] {
  const ago = (days: number) => {
    const d = new Date(anchor); d.setDate(anchor.getDate() - days); return d.toISOString()
  }
  return [
    {
      id: uuid(rng), userId: MOCK_USER_ID,
      prayerName: 'Fajr', metric: 'completed', targetValue: 5,
      period: 'weekly', startDate: ago(7), endDate: null,
      isActive: true, isCompleted: false, completedDate: null,
      createdAt: ago(30),
    },
    {
      id: uuid(rng), userId: MOCK_USER_ID,
      prayerName: 'all', metric: 'inJamaat', targetValue: 20,
      period: 'monthly', startDate: ago(30), endDate: null,
      isActive: true, isCompleted: false, completedDate: null,
      createdAt: ago(60),
    },
    {
      id: uuid(rng), userId: MOCK_USER_ID,
      prayerName: 'all', metric: 'streak', targetValue: 7,
      period: 'custom', startDate: ago(90), endDate: ago(60),
      isActive: false, isCompleted: true, completedDate: ago(63),
      createdAt: ago(90),
    },
  ]
}

function buildNotifications(): NotificationPreference[] {
  return FIVE_DAILY.map((name, i) => ({
    id: `notif-${name}`,
    userId: MOCK_USER_ID,
    prayerName: name,
    enabled: i !== 2,   // Asr off by default
    timing: 'atStart',
    minutesOffset: 0,
    soundEnabled: true,
    adhanSound: 'makkah',
  }))
}
