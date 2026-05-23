// Thin wrapper around the adhan npm package.
// API mirrors adhan-swift 1.4.0 so this file ports 1:1 to Swift later.
import {
  Coordinates,
  CalculationMethod as AdhanMethod,
  CalculationParameters,
  PrayerTimes,
  Madhab as AdhanMadhab,
} from 'adhan'
import type { CalculationMethod, Madhab, PrayerWindow } from '../types'
import { FIVE_DAILY } from '../types'

// Maps our string enum → adhan library parameter factory
function getParams(method: CalculationMethod, madhab: Madhab): CalculationParameters {
  const factoryMap: Record<CalculationMethod, () => CalculationParameters> = {
    ISNA:     AdhanMethod.NorthAmerica,
    MWL:      AdhanMethod.MuslimWorldLeague,
    Egyptian: AdhanMethod.Egyptian,
    Karachi:  AdhanMethod.Karachi,
    Hanafi:   AdhanMethod.Karachi,  // Hanafi fiqh uses Karachi angles
  }
  const params = (factoryMap[method] ?? AdhanMethod.NorthAmerica)()
  params.madhab = madhab === 'Hanafi' ? AdhanMadhab.Hanafi : AdhanMadhab.Shafi
  return params
}

export function getPrayerWindows(
  lat: number,
  lng: number,
  date: Date,
  method: CalculationMethod,
  madhab: Madhab,
): PrayerWindow[] {
  const coords = new Coordinates(lat, lng)
  const params = getParams(method, madhab)
  const pt = new PrayerTimes(coords, date, params)

  // Next day Fajr for the Isha window end
  const tomorrow = new Date(date)
  tomorrow.setDate(tomorrow.getDate() + 1)
  const ptTomorrow = new PrayerTimes(coords, tomorrow, params)

  const friday = date.getDay() === 5

  return FIVE_DAILY.map((name) => {
    switch (name) {
      case 'Fajr':    return { name, start: pt.fajr,    end: pt.sunrise }
      case 'Dhuhr':   return { name: friday ? 'Jumuah' : 'Dhuhr', start: pt.dhuhr, end: pt.asr } as PrayerWindow
      case 'Asr':     return { name, start: pt.asr,     end: pt.maghrib }
      case 'Maghrib': return { name, start: pt.maghrib, end: pt.isha }
      case 'Isha':    return { name, start: pt.isha,    end: ptTomorrow.fajr }
      default:        return { name, start: pt.dhuhr,   end: pt.asr }
    }
  })
}

export function currentPrayerStatus(window: PrayerWindow, now: Date): 'upcoming' | 'active' | 'ended' {
  if (now < window.start) return 'upcoming'
  if (now <= window.end)  return 'active'
  return 'ended'
}
