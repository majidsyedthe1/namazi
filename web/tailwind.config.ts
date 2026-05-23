import type { Config } from 'tailwindcss'

// Import theme colors so Tailwind's purge scanner picks up the values
// and we get utilities like bg-surface, text-on-time, etc.
const config: Config = {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Status colors
        'on-time':  'var(--color-on-time)',
        'late':     'var(--color-late)',
        'missed':   'var(--color-missed)',
        'upcoming': 'var(--color-upcoming)',
        'qada':     'var(--color-qada)',
        // UI chrome
        'bg':       'var(--color-bg)',
        'surface':  'var(--color-surface)',
        'accent':   'var(--color-accent)',
        'jamaat':   'var(--color-jamaat)',
        'muted':    'var(--color-muted)',
      },
      animation: {
        'pulse-slow': 'pulse 2.5s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
    },
  },
  plugins: [],
}

export default config
