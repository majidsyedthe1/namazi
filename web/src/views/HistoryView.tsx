import { useState } from 'react'
import { useStore } from '../store/useStore'
import { THEME } from '../theme/prayerStyle'
import { FIVE_DAILY } from '../types'
import type { PrayerRecord } from '../types'

const CELL = 13
const GAP  = 3
const DAYS_OF_WEEK = ['S','M','T','W','T','F','S']

function dateKey(d: Date) { return d.toISOString().slice(0, 10) }

function completionColor(count: number): string {
  if (count === 0) return 'rgba(255,255,255,0.06)'
  if (count <= 1)  return `${THEME.onTime}33`
  if (count <= 2)  return `${THEME.onTime}66`
  if (count <= 3)  return `${THEME.onTime}99`
  if (count <= 4)  return `${THEME.onTime}cc`
  return THEME.onTime
}

interface DayInfo {
  date: Date
  key: string
  count: number
  records: PrayerRecord[]
}

export default function HistoryView() {
  const records = useStore(s => s.records)
  const [selected, setSelected] = useState<DayInfo | null>(null)

  // Build a map from dateKey → completion count
  const countMap = new Map<string, number>()
  const recordMap = new Map<string, PrayerRecord[]>()
  for (const r of records) {
    if (r.status !== 'missed') {
      countMap.set(r.prayerDate, (countMap.get(r.prayerDate) ?? 0) + 1)
    }
    const list = recordMap.get(r.prayerDate) ?? []
    list.push(r)
    recordMap.set(r.prayerDate, list)
  }

  // Build 52 weeks of cells ending at today
  const today = new Date(); today.setHours(0,0,0,0)
  const startOfGrid = new Date(today)
  startOfGrid.setDate(today.getDate() - today.getDay() - 51 * 7)

  const weeks: DayInfo[][] = []
  const cursor = new Date(startOfGrid)
  for (let w = 0; w < 53; w++) {
    const week: DayInfo[] = []
    for (let d = 0; d < 7; d++) {
      const key = dateKey(cursor)
      week.push({
        date: new Date(cursor),
        key,
        count: countMap.get(key) ?? 0,
        records: recordMap.get(key) ?? [],
      })
      cursor.setDate(cursor.getDate() + 1)
    }
    weeks.push(week)
  }

  // Month labels
  const monthLabels: { label: string; col: number }[] = []
  weeks.forEach((week, wi) => {
    const first = week[0].date
    if (first.getDate() <= 7 || wi === 0) {
      const label = first.toLocaleDateString('en', { month: 'short' })
      if (!monthLabels.length || monthLabels[monthLabels.length - 1].label !== label) {
        monthLabels.push({ label, col: wi })
      }
    }
  })

  const totalW = weeks.length * (CELL + GAP)

  return (
    <div className="flex flex-col min-h-full">
      <div className="px-4 pt-12 pb-4">
        <h1 className="text-2xl font-bold text-white">History</h1>
        <p className="text-muted text-sm mt-1">52 weeks of prayer</p>
      </div>

      {/* Heatmap */}
      <div className="px-4 overflow-x-auto">
        <div style={{ minWidth: totalW + 24 }}>
          {/* Month labels */}
          <div className="relative h-5 mb-1" style={{ width: totalW }}>
            {monthLabels.map(({ label, col }) => (
              <span
                key={`${label}-${col}`}
                className="absolute text-[10px] text-muted"
                style={{ left: col * (CELL + GAP) }}
              >
                {label}
              </span>
            ))}
          </div>

          <div className="flex gap-[3px]">
            {/* Day-of-week labels */}
            <div className="flex flex-col gap-[3px] mr-1">
              {DAYS_OF_WEEK.map((d, i) => (
                <div key={i} style={{ height: CELL, fontSize: 9, lineHeight: `${CELL}px` }}
                     className="text-muted text-right w-3">
                  {i % 2 === 0 ? d : ''}
                </div>
              ))}
            </div>

            {/* Grid */}
            {weeks.map((week, wi) => (
              <div key={wi} className="flex flex-col gap-[3px]">
                {week.map((day) => (
                  <button
                    key={day.key}
                    onClick={() => setSelected(selected?.key === day.key ? null : day)}
                    style={{
                      width: CELL, height: CELL,
                      borderRadius: 3,
                      background: completionColor(day.count),
                      border: selected?.key === day.key ? `1px solid ${THEME.onTime}` : '1px solid transparent',
                    }}
                    title={`${day.date.toLocaleDateString()}: ${day.count}/5`}
                  />
                ))}
              </div>
            ))}
          </div>

          {/* Legend */}
          <div className="flex items-center gap-1.5 mt-3 text-[10px] text-muted">
            <span>0</span>
            {[0,1,2,3,4,5].map(n => (
              <div key={n} style={{ width: CELL, height: CELL, borderRadius: 3, background: completionColor(n) }} />
            ))}
            <span>5/5</span>
          </div>
        </div>
      </div>

      {/* Day detail */}
      {selected && (
        <div className="mx-4 mt-4 bg-surface rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            <div>
              <div className="text-white font-semibold">
                {selected.date.toLocaleDateString('en', { weekday: 'long', day: 'numeric', month: 'long' })}
              </div>
              <div className="text-muted text-xs">{selected.count}/5 prayers completed</div>
            </div>
            <button onClick={() => setSelected(null)} className="text-muted text-xl">×</button>
          </div>

          {FIVE_DAILY.map(name => {
            const rec = selected.records.find(r => r.prayerName === name || r.prayerName === 'Jumuah')
            const completed = rec && rec.status !== 'missed'
            return (
              <div key={name} className="flex items-center gap-3 py-2 border-b border-white/5 last:border-0">
                <div className={`w-2 h-2 rounded-full`}
                     style={{ background: completed ? THEME.onTime : THEME.missed }} />
                <span className="text-sm text-white flex-1">{name}</span>
                {rec ? (
                  <span className="text-xs text-muted">
                    {rec.status === 'onTime' ? 'On time'
                      : rec.status === 'late' ? 'Late'
                      : rec.status === 'missed' ? 'Missed' : 'Qaḍā'}
                    {rec.prayedInJamaat ? ' · Jamaat' : ''}
                  </span>
                ) : (
                  <span className="text-xs text-muted">—</span>
                )}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
