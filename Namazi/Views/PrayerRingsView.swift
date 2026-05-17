import SwiftUI

// 5 concentric rings — Fajr outermost, Isha innermost. Mirrors Apple Activity
// rings but with prayer-status colors. Each ring's fill state:
//   onTime → full teal arc
//   late   → full amber arc
//   missed → faint red track + dashed arc
//   qada   → full teal arc with dashed overlay
//   upcoming → animated partial purple arc (pulses)
//   pending → empty grey track
//
// Pass records for the day; the view picks the matching entry per prayer.

struct PrayerRingsView: View {
    let records: [PrayerRecord]
    /// Which prayer is "next" today; ring shows pulsing purple.
    var upcomingPrayer: PrayerName?
    /// Size of the outer ring. Inner rings shrink accordingly.
    var size: CGFloat = 260

    @State private var pulse: CGFloat = 0.0

    var body: some View {
        ZStack {
            ForEach(Array(PrayerName.fiveDaily.enumerated()), id: \.element) { idx, prayer in
                ringFor(prayer: prayer, indexFromOutside: idx)
            }
            centerLabel
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = 1.0
            }
        }
    }

    // MARK: - Ring per prayer

    private func ringFor(prayer: PrayerName, indexFromOutside idx: Int) -> some View {
        let diameter = size - CGFloat(idx) * (PrayerStyle.ringWidth + PrayerStyle.ringGap) * 2
        let record = recordFor(prayer)
        let isUpcoming = upcomingPrayer == prayer && record == nil

        return ZStack {
            // Track
            Circle()
                .stroke(PrayerStyle.pending, style: StrokeStyle(lineWidth: PrayerStyle.ringWidth, lineCap: .round))

            // Progress
            if let record {
                Circle()
                    .trim(from: 0, to: 1)
                    .stroke(record.prayerStatus.color, style: StrokeStyle(
                        lineWidth: PrayerStyle.ringWidth,
                        lineCap: .round,
                        dash: record.prayerStatus == .qada ? [4, 6] : []
                    ))
                    .rotationEffect(.degrees(-90))
                    .opacity(record.prayerStatus == .missed ? 0.55 : 1.0)
            } else if isUpcoming {
                Circle()
                    .trim(from: 0, to: 0.35)
                    .stroke(PrayerStyle.upcoming, style: StrokeStyle(lineWidth: PrayerStyle.ringWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .opacity(0.55 + pulse * 0.45)
            }
        }
        .frame(width: diameter, height: diameter)
    }

    // MARK: - Center label

    private var centerLabel: some View {
        let completed = records.filter { $0.prayerStatus != .missed }.count
        let total = 5
        return VStack(spacing: 2) {
            Text("\(completed)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("of \(total) prayers")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func recordFor(_ prayer: PrayerName) -> PrayerRecord? {
        // Treat Jumuah as Dhuhr for the Dhuhr ring on Fridays
        records.first(where: {
            $0.prayer == prayer || (prayer == .dhuhr && $0.prayer == .jumuah)
        })
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PrayerRingsView(
            records: [],
            upcomingPrayer: .asr
        )
    }
    .modelContainer(PreviewContainer.shared)
}
