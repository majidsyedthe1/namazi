// Direct port of Namazi/Models/*.swift
// Dates stored as ISO strings for clean JSON serialisation to localStorage.
// Optional Swift fields (Date?, String?) become T | null here.

import type {
  PrayerName, PrayerCategory, SpecialPrayerType, PrayerStatus,
  PrayerSource, LocationType, RakatType, PostureType,
  PostureDetectionSource, CalculationMethod, Madhab,
  NotificationTiming, AdhanSound, GoalMetric, GoalPeriod,
} from './enums'

export interface PrayerRecord {
  id: string
  userId: string
  prayerName: PrayerName
  prayerDate: string             // 'YYYY-MM-DD'
  category: PrayerCategory
  specialType: SpecialPrayerType | null
  windowStart: string | null     // ISO datetime
  windowEnd: string | null
  loggedAt: string
  startedAt: string | null       // set when user taps Start
  endedAt: string | null         // set when user taps Stop
  durationSeconds: number | null
  status: PrayerStatus
  isOnTime: boolean
  userOverrodeStatus: boolean
  source: PrayerSource
  rakats: number
  isTravelling: boolean
  isQada: boolean
  qadaForDate: string | null
  prayedInJamaat: boolean
  locationType: LocationType
  latitude: number | null
  longitude: number | null
  timezone: string | null
  notes: string | null
  updatedAt: string
}

export interface RakatRecord {
  id: string
  prayerRecordId: string
  rakahNumber: number
  type: RakatType
  startedAt: string | null
  durationSeconds: number | null
  surahRecitations: SurahRecitation[]
  postureEvents: PostureEvent[]
}

export interface PostureEvent {
  id: string
  prayerRecordId: string
  rakatRecordId: string | null
  posture: PostureType
  startedAt: string
  durationSeconds: number
  rakahNumber: number
  pitchAngleDegrees: number
  detectionSource: PostureDetectionSource
}

export interface SurahRecitation {
  id: string
  rakatRecordId: string
  surahNumber: number
  surahName: string
  orderInRakat: number
  isFullSurah: boolean
  ayahStart: number | null
  ayahEnd: number | null
}

export interface UserSettings {
  id: string
  userId: string
  calculationMethod: CalculationMethod
  madhab: Madhab
  isTravelMode: boolean
  highLatitudeMode: boolean
  latitude: number
  longitude: number
  timezone: string
  city: string
  country: string
  locationAutoDetect: boolean
  lastUpdated: string
}

export interface UserPrayerStats {
  id: string
  userId: string
  prayerName: string             // 'overall' | PrayerName
  currentStreak: number
  longestStreak: number
  totalCompleted: number
  totalOnTime: number
  totalInJamaat: number
  totalQada: number
  lastPrayedDate: string | null
  lastUpdated: string
}

export interface Goal {
  id: string
  userId: string
  prayerName: string             // 'all' or a PrayerName
  metric: GoalMetric
  targetValue: number
  period: GoalPeriod
  startDate: string
  endDate: string | null
  isActive: boolean
  isCompleted: boolean
  completedDate: string | null
  createdAt: string
}

export interface NotificationPreference {
  id: string
  userId: string
  prayerName: PrayerName
  enabled: boolean
  timing: NotificationTiming
  minutesOffset: number
  soundEnabled: boolean
  adhanSound: AdhanSound | null
}

// Convenience type used by hooks and components
export interface PrayerWindow {
  name: PrayerName
  start: Date
  end: Date
}
