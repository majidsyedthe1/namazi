// Apple Workout-style start/stop prayer logger.
// Stage 1: Start button. Stage 2 (after Stop): context form + Complete.
// Also has a "Log manually" path that skips the timer.
import { useEffect, useState } from 'react'
import { useStore } from '../store/useStore'
import { PRAYER_DISPLAY, PRAYER_EMOJI, DEFAULT_RAKATS, TRAVEL_RAKATS } from '../theme/prayerStyle'
import type { LocationType, PrayerName, PrayerRecord, PrayerStatus, PrayerWindow } from '../types'

interface Props {
  prayerName: PrayerName
  window: PrayerWindow
  prayerDate: string
  existingRecord: PrayerRecord | null
  onClose: () => void
}

type Stage = 'start' | 'form' | 'complete'

function elapsed(from: string): number {
  return Math.floor((Date.now() - new Date(from).getTime()) / 1000)
}

function fmtDur(s: number) {
  const m = Math.floor(s / 60), sec = s % 60
  return `${m}m ${String(sec).padStart(2,'0')}s`
}

const LOCATION_OPTIONS: LocationType[] = ['home','masjid','work','travel','other']
const LOCATION_LABELS: Record<LocationType, string> = {
  home: 'Home', masjid: 'Masjid', work: 'Work', travel: 'Travel', other: 'Other',
}

export default function LogSheet({ prayerName, window: win, prayerDate, existingRecord, onClose }: Props) {
  const { logPrayer, startTimer, stopTimer, clearTimer, activeTimer, settings } = useStore()
  const [stage, setStage] = useState<Stage>(() => {
    if (existingRecord) return 'complete'
    if (activeTimer?.prayerName === prayerName) return 'form'
    return 'start'
  })

  // Form state
  const defaultRakats = settings.isTravelMode
    ? (TRAVEL_RAKATS[prayerName] ?? DEFAULT_RAKATS[prayerName] ?? 4)
    : (DEFAULT_RAKATS[prayerName] ?? 4)

  const [status, setStatus] = useState<PrayerStatus>('onTime')
  const [jamaat, setJamaat]           = useState(false)
  const [location, setLocation]       = useState<LocationType>('home')
  const [notes, setNotes]             = useState('')
  const [rakats, setRakats]           = useState(defaultRakats)
  const [stoppedAt, setStoppedAt]     = useState<string | null>(null)
  const [durationSec, setDurationSec] = useState<number | null>(null)
  const [elapsedSec, setElapsedSec]   = useState(0)

  // Tick while timer is running in Stage 1 display / Stage 2
  useEffect(() => {
    if (stage !== 'form' || !activeTimer) return
    const id = setInterval(() => setElapsedSec(elapsed(activeTimer.startedAt)), 1000)
    return () => clearInterval(id)
  }, [stage, activeTimer])

  // Auto-set status based on whether start was in window
  function autoStatus(startIso: string): PrayerStatus {
    const start = new Date(startIso)
    return start <= win.end ? 'onTime' : 'late'
  }

  function handleStart() {
    startTimer({ prayerName, windowStart: win.start.toISOString(), windowEnd: win.end.toISOString() })
    setStage('form')
  }

  function handleStop() {
    const timer = stopTimer()
    const now = new Date().toISOString()
    setStoppedAt(now)
    const dur = timer ? elapsed(timer.startedAt) : 0
    setDurationSec(dur)
    if (timer) setStatus(autoStatus(timer.startedAt))
    clearTimer()
    // stage stays 'form' but timer is gone — show the completion form
  }

  function handleManual() {
    setStatus(new Date() <= win.end ? 'onTime' : 'late')
    setStage('form')
  }

  function handleSubmit() {
    const timer = activeTimer?.prayerName === prayerName ? activeTimer : null
    const startedAt  = timer?.startedAt ?? stoppedAt ?? undefined
    const endedAt    = stoppedAt ?? undefined
    const durSec     = durationSec ?? undefined

    logPrayer({
      prayerName,
      prayerDate,
      status,
      windowStart: win.start.toISOString(),
      windowEnd:   win.end.toISOString(),
      startedAt,
      endedAt,
      durationSeconds: durSec,
      prayedInJamaat: jamaat,
      locationType: location,
      notes: notes.trim() || undefined,
    })
    onClose()
  }

  const timerRunning = activeTimer?.prayerName === prayerName && !stoppedAt

  return (
    <>
      <div className="sheet-backdrop" onClick={onClose} />
      <div className="sheet">
        {/* Drag handle */}
        <div className="flex justify-center pt-3 pb-1">
          <div className="w-10 h-1 bg-white/20 rounded-full" />
        </div>

        {/* Header */}
        <div className="flex items-center gap-2 px-5 py-3 border-b border-white/10">
          <span className="text-2xl">{PRAYER_EMOJI[prayerName]}</span>
          <div>
            <div className="font-semibold text-white">{PRAYER_DISPLAY[prayerName]}</div>
            <div className="text-xs text-muted">
              {win.start.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })} –{' '}
              {win.end.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' })}
            </div>
          </div>
        </div>

        <div className="px-5 py-4 max-h-[70vh] overflow-y-auto">

          {/* ── Stage: Start ── */}
          {stage === 'start' && (
            <div className="flex flex-col gap-4">
              <button
                onClick={handleStart}
                className="w-full py-4 rounded-2xl font-bold text-bg text-lg"
                style={{ background: 'var(--color-accent)' }}
              >
                ▶ Start Prayer
              </button>
              <button onClick={handleManual} className="text-muted text-sm text-center">
                Log manually (forgot to start?)
              </button>
            </div>
          )}

          {/* ── Stage: Form (after Start or Manual) ── */}
          {stage === 'form' && (
            <div className="flex flex-col gap-4">
              {/* Elapsed time */}
              {timerRunning ? (
                <div className="text-center py-2">
                  <div className="text-4xl font-mono font-bold text-accent">
                    {fmtDur(elapsedSec)}
                  </div>
                  <div className="text-xs text-muted mt-1">Prayer in progress</div>
                  <button
                    onClick={handleStop}
                    className="mt-4 px-6 py-2 rounded-xl bg-missed/20 text-missed font-semibold"
                  >
                    ■ Stop
                  </button>
                </div>
              ) : durationSec !== null ? (
                <div className="text-center py-1">
                  <div className="text-2xl font-semibold text-white">{fmtDur(durationSec)}</div>
                  <div className="text-xs text-muted">Duration recorded</div>
                </div>
              ) : null}

              {/* Show form only when timer stopped or in manual mode */}
              {(!timerRunning) && (
                <>
                  {/* Status picker */}
                  <div>
                    <div className="text-xs text-muted mb-2 uppercase tracking-wide">Status</div>
                    <div className="grid grid-cols-4 gap-2">
                      {(['onTime','late','missed','qada'] as PrayerStatus[]).map(s => (
                        <button
                          key={s}
                          onClick={() => setStatus(s)}
                          className={`py-2 rounded-xl text-xs font-medium border transition-colors ${
                            status === s
                              ? 'border-transparent text-bg font-bold'
                              : 'border-white/10 text-muted'
                          }`}
                          style={status === s ? {
                            background: s === 'onTime' ? 'var(--color-on-time)'
                                      : s === 'late'   ? 'var(--color-late)'
                                      : s === 'missed' ? 'var(--color-missed)'
                                      : 'var(--color-qada)',
                          } : {}}
                        >
                          {s === 'onTime' ? 'On Time' : s === 'late' ? 'Late'
                            : s === 'missed' ? 'Missed' : 'Qaḍā'}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Rakats */}
                  <div className="flex items-center justify-between bg-bg/40 rounded-xl px-4 py-3">
                    <span className="text-sm text-white">Rakats</span>
                    <div className="flex items-center gap-3">
                      <button onClick={() => setRakats(r => Math.max(1, r - 1))}
                              className="w-7 h-7 rounded-full bg-white/10 text-white font-bold">−</button>
                      <span className="w-6 text-center font-semibold text-white">{rakats}</span>
                      <button onClick={() => setRakats(r => Math.min(12, r + 1))}
                              className="w-7 h-7 rounded-full bg-white/10 text-white font-bold">+</button>
                    </div>
                  </div>

                  {/* Jamaat toggle */}
                  <div className="flex items-center justify-between bg-bg/40 rounded-xl px-4 py-3">
                    <span className="text-sm text-white">Prayed in Jamaat</span>
                    <button
                      onClick={() => setJamaat(j => !j)}
                      className={`w-12 h-6 rounded-full transition-colors relative ${jamaat ? 'bg-accent' : 'bg-white/20'}`}
                    >
                      <span className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${jamaat ? 'left-7' : 'left-1'}`} />
                    </button>
                  </div>

                  {/* Location */}
                  <div>
                    <div className="text-xs text-muted mb-2 uppercase tracking-wide">Location</div>
                    <div className="flex gap-2 flex-wrap">
                      {LOCATION_OPTIONS.map(loc => (
                        <button
                          key={loc}
                          onClick={() => setLocation(loc)}
                          className={`px-3 py-1.5 rounded-xl text-xs font-medium border transition-colors ${
                            location === loc
                              ? 'bg-accent text-bg border-transparent font-bold'
                              : 'border-white/10 text-muted'
                          }`}
                        >
                          {LOCATION_LABELS[loc]}
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* Notes */}
                  <div>
                    <div className="text-xs text-muted mb-2 uppercase tracking-wide">Notes</div>
                    <textarea
                      value={notes}
                      onChange={e => setNotes(e.target.value)}
                      placeholder="Optional reflection…"
                      rows={2}
                      className="w-full bg-bg/40 rounded-xl px-3 py-2 text-sm text-white placeholder-white/20 resize-none outline-none border border-white/10 focus:border-accent/50"
                    />
                  </div>

                  <button
                    onClick={handleSubmit}
                    className="w-full py-3.5 rounded-2xl font-bold text-bg"
                    style={{ background: 'var(--color-accent)' }}
                  >
                    ✓ Complete Prayer
                  </button>
                </>
              )}
            </div>
          )}

          {/* ── Stage: Already logged ── */}
          {stage === 'complete' && existingRecord && (
            <div className="flex flex-col items-center gap-3 py-4">
              <div className="text-4xl">✅</div>
              <div className="text-white font-semibold">Already logged</div>
              <div className="text-muted text-sm">
                {existingRecord.status === 'onTime' ? 'On time'
                  : existingRecord.status === 'late' ? 'Late'
                  : existingRecord.status === 'missed' ? 'Missed' : 'Qaḍā'}
                {existingRecord.prayedInJamaat ? ' · Jamaat' : ''}
                {existingRecord.durationSeconds
                  ? ` · ${fmtDur(existingRecord.durationSeconds)}`
                  : ''}
              </div>
              {existingRecord.notes && (
                <div className="text-muted text-xs italic">"{existingRecord.notes}"</div>
              )}
            </div>
          )}
        </div>
      </div>
    </>
  )
}
