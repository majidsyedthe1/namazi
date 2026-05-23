// ── THEME ── edit only this block to retheme the entire app ──────────────────
// No other file in the codebase contains hardcoded color values.
export const THEME = {
  // Status colors (the main visual language of the app)
  onTime:   '#4ADE80',              // bright green  — shown most, the goal
  late:     '#FCD34D',              // warm yellow
  missed:   '#F87171',              // soft red
  upcoming: '#A78BFA',              // lavender — animated pulse on active ring
  qada:     '#4ADE80',              // same hue as onTime, dashed ring in component

  // UI chrome
  bg:       '#071A0A',              // very dark green-black page background
  surface:  '#0F2912',              // card / sheet / bottom-bar background
  accent:   '#4ADE80',              // buttons, active tab indicator, links
  inJamaat: '#FCD34D',              // gold dot on prayer rows
  muted:    'rgba(255,255,255,0.35)',

  // Ring geometry (kept here so the whole visual is one edit)
  ringWidth: 14,                    // SVG stroke-width in px
  ringGap:   5,                     // gap between concentric rings in px
} as const
// ─────────────────────────────────────────────────────────────────────────────

import type { PrayerName, PrayerStatus, PostureType } from '../types'

export const STATUS_COLOR: Record<PrayerStatus, string> = {
  onTime: THEME.onTime,
  late:   THEME.late,
  missed: THEME.missed,
  qada:   THEME.qada,
}

export const STATUS_LABEL: Record<PrayerStatus, string> = {
  onTime: 'On time',
  late:   'Late',
  missed: 'Missed',
  qada:   'Qaḍā',
}

export const STATUS_BG: Record<PrayerStatus, string> = {
  onTime: 'rgba(74,222,128,0.15)',
  late:   'rgba(252,211,77,0.15)',
  missed: 'rgba(248,113,113,0.15)',
  qada:   'rgba(74,222,128,0.15)',
}

export const PRAYER_EMOJI: Record<PrayerName, string> = {
  Fajr:    '🌅',
  Dhuhr:   '☀️',
  Asr:     '🌤️',
  Maghrib: '🌇',
  Isha:    '🌙',
  Jumuah:  '🕌',
  Eid:     '🌙',
  Janazah: '🤲',
  Tarawih: '🌙',
  Witr:    '🌙',
}

export const PRAYER_DISPLAY: Record<PrayerName, string> = {
  Fajr:    'Fajr',
  Dhuhr:   'Dhuhr',
  Asr:     'Asr',
  Maghrib: 'Maghrib',
  Isha:    'Isha',
  Jumuah:  "Jumu'ah",
  Eid:     'Eid',
  Janazah: 'Janazah',
  Tarawih: 'Tarawih',
  Witr:    'Witr',
}

// Default rakat counts per prayer (non-travel)
export const DEFAULT_RAKATS: Partial<Record<PrayerName, number>> = {
  Fajr:    2,
  Dhuhr:   4,
  Asr:     4,
  Maghrib: 3,
  Isha:    4,
  Jumuah:  2,
  Witr:    3,
}

// Reduced rakat counts when travel mode is on
export const TRAVEL_RAKATS: Partial<Record<PrayerName, number>> = {
  Fajr:    2,
  Dhuhr:   2,
  Asr:     2,
  Maghrib: 3,
  Isha:    2,
}

export const POSTURE_COLOR: Record<PostureType, string> = {
  qiyam:     THEME.upcoming,
  ruku:      THEME.onTime,
  sajda:     THEME.inJamaat,
  jalsa:     THEME.late,
  tashahhud: '#67E8F9',
}

export const POSTURE_LABEL: Record<PostureType, string> = {
  qiyam:     'Qiyām',
  ruku:      'Rukūʿ',
  sajda:     'Sajda',
  jalsa:     'Jalsa',
  tashahhud: 'Tashahhud',
}
