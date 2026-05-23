// Concentric SVG ring dial — one ring per daily prayer.
// Mirrors PrayerRingsView.swift: Circle().trim(from:to:).stroke()
import { THEME, STATUS_COLOR } from '../theme/prayerStyle'
import type { PrayerName, PrayerStatus } from '../types'
import { FIVE_DAILY } from '../types'

interface RingData {
  name: PrayerName
  status: PrayerStatus | 'upcoming' | 'pending'
}

interface Props {
  rings: RingData[]
  completedCount: number
  onRingClick?: (name: PrayerName) => void
}

const CENTER = 150
const RING_W  = THEME.ringWidth
const RING_GAP = THEME.ringGap

// Outermost ring = Fajr (largest radius), innermost = Isha
const RADII = FIVE_DAILY.map((_, i) => CENTER - 20 - i * (RING_W + RING_GAP))

function ringColor(status: RingData['status']): string {
  if (status === 'upcoming') return THEME.upcoming
  if (status === 'pending')  return 'rgba(255,255,255,0.08)'
  return STATUS_COLOR[status as PrayerStatus]
}

function fillFraction(status: RingData['status']): number {
  if (status === 'pending')  return 0
  if (status === 'upcoming') return 0.35
  return 1
}

export default function PrayerDial({ rings, completedCount, onRingClick }: Props) {
  const size = CENTER * 2
  const circumferences = RADII.map(r => 2 * Math.PI * r)

  return (
    <div className="flex flex-col items-center">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        {rings.map((ring, i) => {
          const r   = RADII[i]
          const c   = circumferences[i]
          const frac = fillFraction(ring.status)
          const col  = ringColor(ring.status)
          const isUpcoming = ring.status === 'upcoming'
          const isQada     = ring.status === 'qada'

          // Start arc at top (–90°)
          const offset = c * (1 - frac)

          return (
            <g key={ring.name}
               style={{ cursor: onRingClick ? 'pointer' : 'default' }}
               onClick={() => onRingClick?.(ring.name)}>
              {/* Track (full grey circle) */}
              <circle
                cx={CENTER} cy={CENTER} r={r}
                fill="none"
                stroke="rgba(255,255,255,0.07)"
                strokeWidth={RING_W}
              />
              {/* Fill arc */}
              {frac > 0 && (
                <circle
                  cx={CENTER} cy={CENTER} r={r}
                  fill="none"
                  stroke={col}
                  strokeWidth={RING_W}
                  strokeDasharray={isQada ? `4 6` : `${c} ${c}`}
                  strokeDashoffset={isQada ? 0 : offset}
                  strokeLinecap="round"
                  transform={`rotate(-90 ${CENTER} ${CENTER})`}
                  className={isUpcoming ? 'ring-pulse' : undefined}
                  style={{ transition: 'stroke-dashoffset 0.5s ease' }}
                />
              )}
            </g>
          )
        })}

        {/* Center label */}
        <text x={CENTER} y={CENTER - 8} textAnchor="middle" fill="#fff"
              fontSize={28} fontWeight={700} fontFamily="system-ui">
          {completedCount}/5
        </text>
        <text x={CENTER} y={CENTER + 14} textAnchor="middle"
              fill="rgba(255,255,255,0.45)" fontSize={13} fontFamily="system-ui">
          prayers
        </text>
      </svg>
    </div>
  )
}
