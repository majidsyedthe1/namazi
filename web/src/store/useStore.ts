import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { generateMockData } from '../lib/mockData'
import type {
  PrayerRecord, UserSettings, UserPrayerStats,
  Goal, NotificationPreference, PrayerStatus, LocationType, PrayerName,
} from '../types'
import { FIVE_DAILY } from '../types'
import { DEFAULT_RAKATS, TRAVEL_RAKATS } from '../theme/prayerStyle'

interface ActiveTimer {
  prayerName: PrayerName
  startedAt: string        // ISO
  windowStart: string
  windowEnd: string
}

interface AppState {
  settings: UserSettings
  records: PrayerRecord[]
  stats: UserPrayerStats[]
  goals: Goal[]
  notifications: NotificationPreference[]
  activeTimer: ActiveTimer | null
  _hydrated: boolean

  // Actions
  hydrate: () => void
  updateSettings: (patch: Partial<UserSettings>) => void
  logPrayer: (opts: LogPrayerOpts) => void
  startTimer: (opts: Pick<ActiveTimer, 'prayerName' | 'windowStart' | 'windowEnd'>) => void
  stopTimer: () => ActiveTimer | null
  clearTimer: () => void
  rebuildStats: () => void
}

interface LogPrayerOpts {
  prayerName: PrayerName
  prayerDate: string         // 'YYYY-MM-DD'
  status: PrayerStatus
  windowStart: string
  windowEnd: string
  startedAt?: string
  endedAt?: string
  durationSeconds?: number
  prayedInJamaat?: boolean
  locationType?: LocationType
  notes?: string
  qadaForDate?: string
}

export const useStore = create<AppState>()(
  persist(
    (set, get) => ({
      settings: {} as UserSettings,
      records: [],
      stats: [],
      goals: [],
      notifications: [],
      activeTimer: null,
      _hydrated: false,

      hydrate() {
        if (get()._hydrated) return
        const mock = generateMockData()
        set({
          settings: mock.settings,
          records: mock.records,
          stats: mock.stats,
          goals: mock.goals,
          notifications: mock.notifications,
          _hydrated: true,
        })
      },

      updateSettings(patch) {
        set(s => ({ settings: { ...s.settings, ...patch, lastUpdated: new Date().toISOString() } }))
      },

      logPrayer(opts) {
        const { settings } = get()
        const isOnTime = opts.status === 'onTime'
        const isTravelling = settings.isTravelMode
        const rakats = isTravelling
          ? (TRAVEL_RAKATS[opts.prayerName] ?? DEFAULT_RAKATS[opts.prayerName] ?? 4)
          : (DEFAULT_RAKATS[opts.prayerName] ?? 4)

        const now = new Date().toISOString()
        const rec: PrayerRecord = {
          id: crypto.randomUUID(),
          userId: settings.userId,
          prayerName: opts.prayerName,
          prayerDate: opts.prayerDate,
          category: 'fard',
          specialType: opts.prayerName === 'Jumuah' ? 'jumuah' : null,
          windowStart: opts.windowStart,
          windowEnd:   opts.windowEnd,
          loggedAt:    now,
          startedAt:   opts.startedAt ?? null,
          endedAt:     opts.endedAt   ?? null,
          durationSeconds: opts.durationSeconds ?? null,
          status:          opts.status,
          isOnTime,
          userOverrodeStatus: false,
          source: 'manual',
          rakats,
          isTravelling,
          isQada:      opts.status === 'qada',
          qadaForDate: opts.qadaForDate ?? null,
          prayedInJamaat: opts.prayedInJamaat ?? false,
          locationType:   opts.locationType ?? 'home',
          latitude:  settings.latitude,
          longitude: settings.longitude,
          timezone:  settings.timezone,
          notes: opts.notes ?? null,
          updatedAt: now,
        }

        set(s => ({ records: [...s.records, rec] }))
        get().rebuildStats()
      },

      startTimer(opts) {
        set({ activeTimer: { ...opts, startedAt: new Date().toISOString() } })
      },

      stopTimer() {
        const timer = get().activeTimer
        return timer
      },

      clearTimer() {
        set({ activeTimer: null })
      },

      rebuildStats() {
        const { records } = get()
        const anchor = new Date()
        const stats: UserPrayerStats[] = []
        const now = anchor.toISOString().slice(0, 10)

        for (const pname of [...FIVE_DAILY, 'overall'] as string[]) {
          const isOverall = pname === 'overall'
          const relevant = isOverall
            ? records.filter(r => FIVE_DAILY.includes(r.prayerName))
            : records.filter(r => r.prayerName === pname || r.prayerName === (pname === 'Dhuhr' ? 'Jumuah' : ''))

          const completed = relevant.filter(r => r.status !== 'missed')
          const daySet = new Set<string>()

          if (isOverall) {
            const byDay = new Map<string, number>()
            for (const r of completed) byDay.set(r.prayerDate, (byDay.get(r.prayerDate) ?? 0) + 1)
            for (const [day, count] of byDay) if (count >= 5) daySet.add(day)
          } else {
            for (const r of completed) daySet.add(r.prayerDate)
          }

          let currentStreak = 0, longestStreak = 0, streak = 0
          const check = new Date(anchor); check.setHours(0,0,0,0)
          if (!daySet.has(now)) check.setDate(check.getDate() - 1)
          let started = false

          for (let i = 0; i < 365; i++) {
            const key = check.toISOString().slice(0, 10)
            if (daySet.has(key)) {
              streak++
              longestStreak = Math.max(longestStreak, streak)
              if (!started) { currentStreak = streak }
            } else {
              if (!started && streak > 0) started = true
              longestStreak = Math.max(longestStreak, streak)
              streak = 0
            }
            check.setDate(check.getDate() - 1)
          }

          const lastPrayed = completed.reduce((best, r) =>
            !best || r.prayerDate > best ? r.prayerDate : best, null as string | null)

          const existing = get().stats.find(s => s.prayerName === pname)
          stats.push({
            id: existing?.id ?? `stats-${pname}`,
            userId: get().settings.userId,
            prayerName: pname,
            currentStreak,
            longestStreak,
            totalCompleted: completed.length,
            totalOnTime:    relevant.filter(r => r.isOnTime).length,
            totalInJamaat:  relevant.filter(r => r.prayedInJamaat).length,
            totalQada:      relevant.filter(r => r.isQada).length,
            lastPrayedDate: lastPrayed,
            lastUpdated: new Date().toISOString(),
          })
        }
        set({ stats })
      },
    }),
    {
      name: 'namazi-store',
      partialize: s => ({
        settings: s.settings,
        records: s.records,
        stats: s.stats,
        goals: s.goals,
        notifications: s.notifications,
        activeTimer: s.activeTimer,
        _hydrated: s._hydrated,
      }),
    }
  )
)

// Convenience selectors
export const selectTodayRecords = (state: AppState, dateKey: string) =>
  state.records.filter(r => r.prayerDate === dateKey)

export const selectOverallStats = (state: AppState) =>
  state.stats.find(s => s.prayerName === 'overall')

export const selectPrayerStats = (state: AppState, name: string) =>
  state.stats.find(s => s.prayerName === name)
