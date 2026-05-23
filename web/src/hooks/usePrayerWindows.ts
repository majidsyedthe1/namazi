import { useMemo } from 'react'
import { getPrayerWindows } from '../lib/prayerTimes'
import { useStore } from '../store/useStore'
import type { PrayerWindow } from '../types'

export function usePrayerWindows(date: Date): PrayerWindow[] {
  const { calculationMethod, madhab, latitude, longitude } = useStore(s => s.settings)
  return useMemo(
    () => getPrayerWindows(latitude || 40.7128, longitude || -74.006, date, calculationMethod, madhab),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [latitude, longitude, calculationMethod, madhab, date.toDateString()],
  )
}
