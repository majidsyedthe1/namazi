// Direct port of Namazi/Models/PrayerEnums.swift
// All values kept as string literals to match Swift's CloudKit-safe raw values.

export type PrayerName =
  | 'Fajr' | 'Dhuhr' | 'Asr' | 'Maghrib' | 'Isha'
  | 'Jumuah' | 'Eid' | 'Janazah' | 'Tarawih' | 'Witr'

export const FIVE_DAILY: PrayerName[] = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']

export type PrayerCategory = 'fard' | 'sunnah' | 'nawafil'

export type SpecialPrayerType = 'jumuah' | 'eid' | 'janazah' | 'shukrana' | 'tarawih' | 'other'

export type PrayerStatus = 'onTime' | 'late' | 'missed' | 'qada'

export type PrayerSource = 'watch' | 'manual'

export type LocationType = 'home' | 'masjid' | 'work' | 'travel' | 'other'

export type RakatType = 'fard' | 'sunnah' | 'witr'

export type PostureType = 'qiyam' | 'ruku' | 'sajda' | 'jalsa' | 'tashahhud'

export type PostureDetectionSource = 'watch_auto' | 'watch_manual'

export type CalculationMethod = 'ISNA' | 'MWL' | 'Hanafi' | 'Egyptian' | 'Karachi'

export type Madhab = 'Hanafi' | 'Shafi' | 'Maliki' | 'Hanbali'

export type NotificationTiming = 'atStart' | 'minutesAfterStart' | 'minutesBeforeEnd'

export type AdhanSound = 'makkah' | 'madinah' | 'default'

export type GoalMetric = 'completed' | 'onTime' | 'inJamaat' | 'streak' | 'qada'

export type GoalPeriod = 'daily' | 'weekly' | 'monthly' | 'custom'
