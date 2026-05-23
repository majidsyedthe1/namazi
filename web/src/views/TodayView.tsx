import { useState } from 'react'
import { useStore, selectTodayRecords, selectOverallStats } from '../store/useStore'
import { usePrayerWindows } from '../hooks/usePrayerWindows'
import { useNow } from '../hooks/useNow'
import PrayerDial from '../components/PrayerDial'
import LogSheet from '../components/LogSheet'
import {
  PRAYER_EMOJI, PRAYER_DISPLAY, STATUS_COLOR, STATUS_LABEL, STATUS_BG,
} from '../theme/prayerStyle'
import { FIVE_DAILY } from '../types'
import type { PrayerName, PrayerWindow } from '../types'

function formatTime(d: Date) {
  return d.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })
}

function dateKey(d: Date) { return d.toISOString().slice(0, 10) }

function isoWd(d: Date) {
  return d.toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long' })
}

export default function TodayView() {
  const [selectedPrayer, setSelectedPrayer] = useState<PrayerName | null>(null)
  const [viewDate, setViewDate] = useState(() => {
    const d = new Date(); d.setHours(0,0,0,0); return d
  })

  const now = useNow()
  const windows = usePrayerWindows(viewDate)
  const records = useStore(s => selectTodayRecords(s, dateKey(viewDate)))
  const stats   = useStore(selectOverallStats)
  const activeTimer = useStore(s => s.activeTimer)

  const isToday = dateKey(viewDate) === dateKey(new Date())

  function prayerStatus(w: PrayerWindow) {
    const rec = records.find(r => r.prayerName === w.name)
    if (rec) return rec.status
    if (!isToday) return 'pending' as const
    if (now < w.start) return 'upcoming' as const
    if (now <= w.end)  return 'pending' as const
    return 'missed' as const
  }

  const ringData = FIVE_DAILY.map((name, i) => ({
    name,
    status: prayerStatus(windows[i] ?? { name, start: new Date(), end: new Date() }),
  }))

  const completedCount = records.filter(r => r.status !== 'missed').length

  function shiftDay(delta: number) {
    const d = new Date(viewDate)
    d.setDate(d.getDate() + delta)
    setViewDate(d)
  }

  const selectedWindow = windows.find(w => w.name === selectedPrayer)

  return (
    <div className="flex flex-col min-h-full pb-2">
      {/* Header */}
      <div className="flex items-center justify-between px-4 pt-12 pb-2">
        <button onClick={() => shiftDay(-1)} className="text-muted text-xl px-2">‹</button>
        <div className="text-center">
          <div className="text-sm text-muted">{isoWd(viewDate)}</div>
          {isToday && <div className="text-xs text-accent font-medium">Today</div>}
        </div>
        <button
          onClick={() => shiftDay(1)}
          disabled={isToday}
          className={`text-xl px-2 ${isToday ? 'opacity-0 pointer-events-none' : 'text-muted'}`}
        >›</button>
      </div>

      {/* Streak badge */}
      {stats && (
        <div className="flex justify-center pb-1">
          <span className="text-xs bg-surface px-3 py-1 rounded-full text-accent font-medium">
            🔥 {stats.currentStreak} day streak
          </span>
        </div>
      )}

      {/* Prayer Dial */}
      <div className="flex justify-center py-4">
        <PrayerDial
          rings={ringData}
          completedCount={completedCount}
          onRingClick={setSelectedPrayer}
        />
      </div>

      {/* Quick stats */}
      {stats && (
        <div className="flex gap-2 mx-4 mb-4">
          {[
            { label: 'On time', value: `${stats.totalOnTime}` },
            { label: 'Jamaat',  value: `${stats.totalInJamaat}` },
            { label: 'Best',    value: `${stats.longestStreak}d` },
          ].map(item => (
            <div key={item.label} className="flex-1 bg-surface rounded-xl py-2 text-center">
              <div className="text-white font-bold text-base">{item.value}</div>
              <div className="text-muted text-xs">{item.label}</div>
            </div>
          ))}
        </div>
      )}

      {/* Prayer rows */}
      <div className="flex flex-col gap-2 px-4">
        {windows.map((w, i) => {
          const status = ringData[i]?.status
          const rec = records.find(r => r.prayerName === w.name)
          const isTimerActive = activeTimer?.prayerName === w.name
          const isLogged = !!rec

          return (
            <button
              key={w.name}
              onClick={() => setSelectedPrayer(w.name)}
              className="w-full flex items-center gap-3 bg-surface rounded-2xl px-4 py-3 text-left"
            >
              <span className="text-2xl">{PRAYER_EMOJI[w.name]}</span>
              <div className="flex-1">
                <div className="font-semibold text-white text-sm">{PRAYER_DISPLAY[w.name]}</div>
                <div className="text-muted text-xs">
                  {formatTime(w.start)} – {formatTime(w.end)}
                  {rec?.prayedInJamaat && <span className="ml-2 text-jamaat">• Jamaat</span>}
                </div>
              </div>
              {isTimerActive ? (
                <span className="text-xs text-accent font-medium animate-pulse">Timing…</span>
              ) : isLogged && status && status !== 'upcoming' && status !== 'pending' ? (
                <span
                  className="text-xs font-medium px-2 py-0.5 rounded-full"
                  style={{ color: STATUS_COLOR[status as keyof typeof STATUS_COLOR], background: STATUS_BG[status as keyof typeof STATUS_BG] }}
                >
                  {STATUS_LABEL[status as keyof typeof STATUS_LABEL]}
                </span>
              ) : (
                <span className="text-xs text-muted">
                  {status === 'upcoming' ? 'Upcoming' : status === 'pending' ? 'Open' : '—'}
                </span>
              )}
            </button>
          )
        })}
      </div>

      {/* Log sheet */}
      {selectedPrayer && selectedWindow && (
        <LogSheet
          prayerName={selectedPrayer}
          window={selectedWindow}
          prayerDate={dateKey(viewDate)}
          existingRecord={records.find(r => r.prayerName === selectedPrayer) ?? null}
          onClose={() => setSelectedPrayer(null)}
        />
      )}
    </div>
  )
}
