import { useStore, selectOverallStats, selectPrayerStats } from '../store/useStore'
import { FIVE_DAILY } from '../types'
import type { PrayerRecord } from '../types'
import { PRAYER_EMOJI, PRAYER_DISPLAY, THEME } from '../theme/prayerStyle'

function pct(num: number, den: number): string {
  if (den === 0) return '0%'
  return `${Math.round((num / den) * 100)}%`
}

// Last 30 days bar chart data
function useLast30(records: PrayerRecord[]) {
  const today = new Date(); today.setHours(0,0,0,0)
  return Array.from({ length: 30 }, (_, i) => {
    const d = new Date(today); d.setDate(today.getDate() - 29 + i)
    const key = d.toISOString().slice(0,10)
    const count = records.filter(r => r.prayerDate === key && r.status !== 'missed').length
    return { key, count }
  })
}

export default function StatsView() {
  const records     = useStore(s => s.records)
  const overall     = useStore(selectOverallStats)
  const allStats    = useStore(s => s.stats)
  const last30      = useLast30(records)
  const maxBar      = 5
  const goals       = useStore(s => s.goals).filter(g => g.isActive)

  return (
    <div className="flex flex-col min-h-full pb-8">
      <div className="px-4 pt-12 pb-4">
        <h1 className="text-2xl font-bold text-white">Stats</h1>
      </div>

      {/* Streak hero */}
      {overall && (
        <div className="mx-4 mb-4 rounded-2xl p-5"
             style={{ background: `linear-gradient(135deg, ${THEME.surface} 0%, rgba(74,222,128,0.15) 100%)` }}>
          <div className="flex items-end gap-2">
            <span className="text-5xl font-bold text-white">{overall.currentStreak}</span>
            <span className="text-muted mb-1">day streak 🔥</span>
          </div>
          <div className="text-xs text-muted mt-1">
            Best: {overall.longestStreak} days · {pct(overall.totalOnTime, overall.totalCompleted)} on time
          </div>
        </div>
      )}

      {/* 30-day bar chart */}
      <div className="mx-4 mb-4 bg-surface rounded-2xl p-4">
        <div className="text-xs text-muted mb-3 uppercase tracking-wide">Last 30 days</div>
        <div className="flex items-end gap-[3px] h-16">
          {last30.map(({ key, count }) => (
            <div key={key} className="flex-1 flex flex-col justify-end">
              <div
                className="rounded-t-sm transition-all"
                style={{
                  height: `${(count / maxBar) * 100}%`,
                  minHeight: count > 0 ? 3 : 0,
                  background: count === 5 ? THEME.onTime
                             : count > 0  ? `${THEME.onTime}88`
                             : 'rgba(255,255,255,0.06)',
                }}
              />
            </div>
          ))}
        </div>
        <div className="flex justify-between text-[9px] text-muted mt-1">
          <span>30d ago</span><span>Today</span>
        </div>
      </div>

      {/* Per-prayer grid */}
      <div className="mx-4 mb-4">
        <div className="text-xs text-muted mb-3 uppercase tracking-wide">Per prayer</div>
        <div className="grid grid-cols-2 gap-3">
          {FIVE_DAILY.map(name => {
            const s = selectPrayerStats({ stats: allStats } as Parameters<typeof selectPrayerStats>[0], name)
            if (!s) return null
            return (
              <div key={name} className="bg-surface rounded-2xl p-4">
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-xl">{PRAYER_EMOJI[name]}</span>
                  <span className="font-semibold text-white text-sm">{PRAYER_DISPLAY[name]}</span>
                </div>
                <div className="text-2xl font-bold text-accent">
                  {pct(s.totalOnTime, s.totalCompleted)}
                </div>
                <div className="text-xs text-muted">on time</div>
                <div className="flex gap-3 mt-2 text-xs text-muted">
                  <span>🔥 {s.currentStreak}d</span>
                  <span>🕌 {s.totalInJamaat}</span>
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {/* Goals */}
      {goals.length > 0 && (
        <div className="mx-4">
          <div className="text-xs text-muted mb-3 uppercase tracking-wide">Active Goals</div>
          {goals.map(g => {
            const relevant = records.filter(r =>
              (g.prayerName === 'all' || r.prayerName === g.prayerName) &&
              r.prayerDate >= g.startDate
            )
            const progress = g.metric === 'completed' ? relevant.filter(r => r.status !== 'missed').length
                           : g.metric === 'inJamaat'  ? relevant.filter(r => r.prayedInJamaat).length
                           : g.metric === 'onTime'    ? relevant.filter(r => r.isOnTime).length
                           : 0
            const frac = Math.min(progress / g.targetValue, 1)
            return (
              <div key={g.id} className="bg-surface rounded-2xl p-4 mb-3">
                <div className="flex justify-between text-sm mb-2">
                  <span className="text-white font-medium">
                    {g.prayerName === 'all' ? 'All prayers' : g.prayerName}{' '}
                    {g.metric === 'completed' ? 'completed' : g.metric === 'inJamaat' ? 'in jamaat' : g.metric}
                  </span>
                  <span className="text-muted">{progress}/{g.targetValue}</span>
                </div>
                <div className="h-2 bg-white/10 rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all"
                    style={{ width: `${frac * 100}%`, background: THEME.onTime }}
                  />
                </div>
                <div className="text-xs text-muted mt-1">{g.period}</div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
