import { useStore } from '../store/useStore'
import { THEME } from '../theme/prayerStyle'
import type { CalculationMethod, Madhab } from '../types'
import { FIVE_DAILY } from '../types'

const CALC_METHODS: CalculationMethod[] = ['ISNA','MWL','Egyptian','Karachi','Hanafi']
const MADHABS: Madhab[] = ['Hanafi','Shafi','Maliki','Hanbali']

const CALC_LABEL: Record<CalculationMethod, string> = {
  ISNA:     'ISNA (North America)',
  MWL:      'Muslim World League',
  Egyptian: 'Egyptian',
  Karachi:  'University of Islamic Sciences, Karachi',
  Hanafi:   'Hanafi',
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="mb-6">
      <div className="text-xs text-muted uppercase tracking-widest px-4 mb-2">{title}</div>
      <div className="bg-surface mx-4 rounded-2xl overflow-hidden">{children}</div>
    </div>
  )
}

function Row({ label, children, last }: { label: string; children: React.ReactNode; last?: boolean }) {
  return (
    <div className={`flex items-center justify-between px-4 py-3 ${!last ? 'border-b border-white/5' : ''}`}>
      <span className="text-sm text-white">{label}</span>
      <div className="text-muted text-sm">{children}</div>
    </div>
  )
}

function Toggle({ value, onChange }: { value: boolean; onChange: (v: boolean) => void }) {
  return (
    <button
      onClick={() => onChange(!value)}
      className={`w-12 h-6 rounded-full transition-colors relative ${value ? 'bg-accent' : 'bg-white/20'}`}
    >
      <span className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${value ? 'left-7' : 'left-1'}`} />
    </button>
  )
}

export default function SettingsView() {
  const { settings, updateSettings, notifications } = useStore()

  if (!settings.userId) return null

  return (
    <div className="flex flex-col min-h-full pb-8">
      <div className="px-4 pt-12 pb-4">
        <h1 className="text-2xl font-bold text-white">Settings</h1>
      </div>

      {/* Location */}
      <Section title="Location">
        <Row label="City">
          <span>{settings.city || '—'}, {settings.country || '—'}</span>
        </Row>
        <Row label="Coordinates">
          <span className="font-mono text-xs">
            {settings.latitude.toFixed(4)}°, {settings.longitude.toFixed(4)}°
          </span>
        </Row>
        <Row label="Timezone" last>
          <span className="text-xs">{settings.timezone}</span>
        </Row>
      </Section>

      {/* Prayer times */}
      <Section title="Prayer Times">
        <Row label="Calculation Method">
          <select
            value={settings.calculationMethod}
            onChange={e => updateSettings({ calculationMethod: e.target.value as CalculationMethod })}
            className="bg-transparent text-muted text-sm outline-none text-right max-w-[160px]"
          >
            {CALC_METHODS.map(m => (
              <option key={m} value={m} style={{ background: THEME.surface }}>{CALC_LABEL[m]}</option>
            ))}
          </select>
        </Row>
        <Row label="Madhab (Asr time)">
          <select
            value={settings.madhab}
            onChange={e => updateSettings({ madhab: e.target.value as Madhab })}
            className="bg-transparent text-muted text-sm outline-none"
          >
            {MADHABS.map(m => (
              <option key={m} value={m} style={{ background: THEME.surface }}>{m}</option>
            ))}
          </select>
        </Row>
        <Row label="High Latitude Mode" last>
          <Toggle
            value={settings.highLatitudeMode}
            onChange={v => updateSettings({ highLatitudeMode: v })}
          />
        </Row>
      </Section>

      {/* Travel */}
      <Section title="Travel">
        <Row label="Travel Mode" last>
          <Toggle
            value={settings.isTravelMode}
            onChange={v => updateSettings({ isTravelMode: v })}
          />
        </Row>
      </Section>

      {/* Notifications (display only for prototype) */}
      <Section title="Notifications">
        {FIVE_DAILY.map((name, i) => {
          const notif = notifications.find(n => n.prayerName === name)
          return (
            <Row key={name} label={name} last={i === 4}>
              <span className={`text-xs ${notif?.enabled ? 'text-accent' : 'text-muted'}`}>
                {notif?.enabled ? 'On' : 'Off'}
              </span>
            </Row>
          )
        })}
      </Section>

      <div className="text-center text-muted text-xs px-4 mt-2">
        Namazi Web Prototype · Forest Night theme
      </div>
    </div>
  )
}
