import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PrayerRecord.prayerDate, order: .reverse) private var allRecords: [PrayerRecord]
    @Query private var stats: [UserPrayerStats]

    @State private var selectedRecord: PrayerRecord?
    @State private var now: Date = Date()

    private let cal = Calendar.namaziGregorian
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    headerBar
                    ringSection
                    statRow
                    prayerList
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .sheet(item: $selectedRecord) { record in
            PrayerDetailSheet(record: record)
        }
        .onReceive(timer) { now = $0 }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text(PrayerFormat.weekdayLong.string(from: now))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            streakBadge
        }
        .padding(.top, 16)
    }

    private var streakBadge: some View {
        let overall = stats.first(where: { $0.prayerName == UserPrayerStats.overallKey })
        let streak = overall?.currentStreak ?? 0
        return HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(PrayerStyle.late)
            Text("\(streak)")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.07), in: Capsule())
    }

    // MARK: - Ring section

    private var ringSection: some View {
        let todaysRecords = recordsForToday()
        let upcoming = upcomingPrayer(now: now, records: todaysRecords)

        return VStack(spacing: 24) {
            PrayerRingsView(
                records: todaysRecords,
                upcomingPrayer: upcoming
            )
            if let upcoming {
                upcomingPill(prayer: upcoming)
            }
        }
        .padding(.vertical, 12)
    }

    private func upcomingPill(prayer: PrayerName) -> some View {
        let windows = PrayerWindowCalculator.windows(
            for: now,
            dayOfYear: cal.ordinality(of: .day, in: .year, for: now) ?? 1
        )
        let start = windows[prayer]?.start ?? now
        let relative = PrayerFormat.relativeShort(from: now, to: start)
        return HStack(spacing: 10) {
            Image(systemName: prayer.symbol)
                .foregroundStyle(PrayerStyle.upcoming)
            Text("Next: \(prayer.displayName) in \(relative)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(PrayerStyle.upcoming.opacity(0.15), in: Capsule())
        .overlay(Capsule().stroke(PrayerStyle.upcoming.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Quick stat row

    private var statRow: some View {
        let today = recordsForToday()
        let onTime = today.filter { $0.prayerStatus == .onTime }.count
        let jamaat = today.filter { $0.prayedInJamaat }.count
        let overall = stats.first(where: { $0.prayerName == UserPrayerStats.overallKey })

        return HStack(spacing: 12) {
            statCard(value: "\(onTime)", label: "On time", color: PrayerStyle.onTime)
            statCard(value: "\(jamaat)", label: "Jamaat", color: PrayerStyle.inJamaat)
            statCard(value: "\(overall?.longestStreak ?? 0)", label: "Best streak", color: PrayerStyle.upcoming)
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Prayer list

    private var prayerList: some View {
        VStack(spacing: 10) {
            ForEach(PrayerName.fiveDaily, id: \.self) { prayer in
                row(for: prayer)
            }
        }
    }

    private func row(for prayer: PrayerName) -> some View {
        let today = recordsForToday()
        let record = today.first(where: {
            $0.prayer == prayer || (prayer == .dhuhr && $0.prayer == .jumuah)
        })

        let windows = PrayerWindowCalculator.windows(
            for: now,
            dayOfYear: cal.ordinality(of: .day, in: .year, for: now) ?? 1
        )
        let lookupName: PrayerName = (record?.prayer == .jumuah ? .jumuah : prayer)
        let window = windows[lookupName]

        return Button {
            if let record { selectedRecord = record }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: lookupName.symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(record?.prayerStatus.color ?? PrayerStyle.pending)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(lookupName.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let window {
                        Text(PrayerFormat.time.string(from: window.start))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
                trailingBadge(record: record)
            }
            .padding(14)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func trailingBadge(record: PrayerRecord?) -> some View {
        if let record {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(record.prayerStatus.color)
                        .frame(width: 8, height: 8)
                    Text(record.prayerStatus.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                if let dur = record.durationSeconds {
                    Text(PrayerFormat.duration(seconds: dur))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if record.prayedInJamaat {
                    Text("Jamaat")
                        .font(.caption2)
                        .foregroundStyle(PrayerStyle.inJamaat)
                }
            }
        } else {
            Text("Pending")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Data helpers

    private func recordsForToday() -> [PrayerRecord] {
        let start = cal.startOfDay(for: now)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }
        return allRecords.filter { $0.prayerDate >= start && $0.prayerDate < end }
    }

    private func upcomingPrayer(now: Date, records: [PrayerRecord]) -> PrayerName? {
        let prayed = Set(records.filter { $0.prayerStatus != .missed }.map { $0.prayer == .jumuah ? PrayerName.dhuhr : $0.prayer })
        let windows = PrayerWindowCalculator.windows(
            for: now,
            dayOfYear: cal.ordinality(of: .day, in: .year, for: now) ?? 1
        )
        // First daily prayer whose window hasn't ended yet and isn't already prayed
        for prayer in PrayerName.fiveDaily {
            guard let window = windows[prayer] else { continue }
            if prayed.contains(prayer) { continue }
            if now < window.end { return prayer }
        }
        return nil
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewContainer.shared)
}
