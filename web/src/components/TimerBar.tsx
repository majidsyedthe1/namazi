// Persistent timer bar shown while a prayer is being timed.
// Mirrors the Apple Workout "active session" banner.
import { useEffect, useState } from 'react'
import { useStore } from '../store/useStore'
import { PRAYER_EMOJI, PRAYER_DISPLAY } from '../theme/prayerStyle'

interface Props {
  onTap?: () => void
}

export default function TimerBar({ onTap }: Props) {
  const { activeTimer } = useStore()
  const [elapsed, setElapsed] = useState(0)

  useEffect(() => {
    if (!activeTimer) return
    const start = new Date(activeTimer.startedAt).getTime()
    const id = setInterval(() => setElapsed(Math.floor((Date.now() - start) / 1000)), 1000)
    return () => clearInterval(id)
  }, [activeTimer])

  if (!activeTimer) return null

  const mm = String(Math.floor(elapsed / 60)).padStart(2, '0')
  const ss = String(elapsed % 60).padStart(2, '0')
  const name = activeTimer.prayerName

  return (
    <button
      onClick={onTap}
      className="w-full flex items-center gap-3 px-4 py-3 bg-surface border-t border-accent/30"
    >
      <span className="relative flex h-3 w-3">
        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-accent opacity-75" />
        <span className="relative inline-flex rounded-full h-3 w-3 bg-accent" />
      </span>
      <span className="text-sm font-medium text-white">
        {PRAYER_EMOJI[name]} {PRAYER_DISPLAY[name]}
      </span>
      <span className="ml-auto font-mono text-accent text-sm font-semibold">
        {mm}:{ss}
      </span>
      <span className="text-xs text-muted">Tap to finish</span>
    </button>
  )
}
