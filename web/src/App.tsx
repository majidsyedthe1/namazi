import { useEffect, useState } from 'react'
import { useStore } from './store/useStore'
import TodayView   from './views/TodayView'
import HistoryView from './views/HistoryView'
import StatsView   from './views/StatsView'
import SettingsView from './views/SettingsView'
import TimerBar from './components/TimerBar'

type Tab = 'today' | 'history' | 'stats' | 'settings'

const TABS: { id: Tab; label: string; emoji: string }[] = [
  { id: 'today',    label: 'Today',   emoji: '🕌' },
  { id: 'history',  label: 'History', emoji: '📅' },
  { id: 'stats',    label: 'Stats',   emoji: '📊' },
  { id: 'settings', label: 'Settings',emoji: '⚙️' },
]

export default function App() {
  const [tab, setTab] = useState<Tab>('today')
  const { hydrate, _hydrated, activeTimer } = useStore()

  useEffect(() => { hydrate() }, [hydrate])

  if (!_hydrated) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="text-muted text-sm">Loading…</div>
      </div>
    )
  }

  return (
    <div className="flex flex-col h-full max-w-[430px] mx-auto">
      {/* Page content */}
      <div className="flex-1 overflow-y-auto">
        {tab === 'today'    && <TodayView />}
        {tab === 'history'  && <HistoryView />}
        {tab === 'stats'    && <StatsView />}
        {tab === 'settings' && <SettingsView />}
      </div>

      {/* Active prayer timer bar (sits above tab bar) */}
      {activeTimer && <TimerBar />}

      {/* Bottom tab bar */}
      <nav className="flex border-t border-white/10 bg-surface shrink-0">
        {TABS.map(t => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className={`flex-1 flex flex-col items-center gap-0.5 py-2 text-xs transition-colors ${
              tab === t.id ? 'text-accent' : 'text-muted'
            }`}
          >
            <span className="text-lg leading-none">{t.emoji}</span>
            {t.label}
          </button>
        ))}
      </nav>
    </div>
  )
}
