import SwiftUI
import SwiftData
import Charts

// Per-prayer breakdown, streaks, and a 30-day completion sparkline.
// Brief says full "Insights" is deferred — this is the lightweight version.

struct StatsView: View {
    @Query private var stats: [UserPrayerStats]
    @Query(sort: \PrayerRecord.prayerDate) private var allRecords: [PrayerRecord]
    @Query(filter: #Predicate<Goal> { $0.isActive == true }) private var activeGoals: [Goal]

    private let cal = Calendar.namaziGregorian

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    streakHero
                    last30DaysChart
                    perPrayerGrid
                    goalsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Stats")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("All-time + last 30 days")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    // MARK: - Streak hero

    private var streakHero: some View {
        let overall = stats.first(where: { $0.prayerName == UserPrayerStats.overallKey })
        return VStack(spacing: 14) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(PrayerStyle.late)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(overall?.currentStreak ?? 0)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Best")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(overall?.longestStreak ?? 0)")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [PrayerStyle.late.opacity(0.25), PrayerStyle.upcoming.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: - Last 30 days chart

    private var last30DaysChart: some View {
        let series = buildLast30Days()
        return VStack(alignment: .leading, spacing: 10) {
            Text("LAST 30 DAYS")
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Chart(series, id: \.day) { point in
                BarMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value("Completed", point.completed)
                )
                .foregroundStyle(PrayerStyle.onTime.gradient)
                .cornerRadius(2)
            }
            .chartYScale(domain: 0...5)
            .chartYAxis {
                AxisMarks(values: [0, 5]) { v in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.07))
                    AxisValueLabel().foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow).day(),
                                   centered: true)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 140)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private struct DayPoint { let day: Date; let completed: Int }

    private func buildLast30Days() -> [DayPoint] {
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -29, to: today)!
        let byDay = Dictionary(grouping: allRecords) { cal.startOfDay(for: $0.prayerDate) }
        return (0...29).map { offset in
            let d = cal.date(byAdding: .day, value: offset, to: start)!
            let rs = (byDay[d] ?? []).filter { $0.prayerStatus != .missed }
            var unique = Set<String>()
            for r in rs {
                let key = r.prayer == .jumuah ? PrayerName.dhuhr.rawValue : r.prayerName
                unique.insert(key)
            }
            return DayPoint(day: d, completed: unique.count)
        }
    }

    // MARK: - Per-prayer grid

    private var perPrayerGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PER PRAYER")
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(PrayerName.fiveDaily, id: \.self) { prayer in
                    perPrayerCard(prayer)
                }
            }
        }
    }

    private func perPrayerCard(_ prayer: PrayerName) -> some View {
        let s = stats.first(where: { $0.prayerName == prayer.rawValue })
        let total = (s?.totalCompleted ?? 0)
        let onTime = (s?.totalOnTime ?? 0)
        let onTimePct = total == 0 ? 0 : Int(Double(onTime) / Double(total) * 100)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: prayer.symbol)
                    .foregroundStyle(PrayerStyle.onTime)
                Text(prayer.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
            }
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(onTimePct)%")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("on time")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                miniMetric("Streak", "\(s?.currentStreak ?? 0)")
                Divider().frame(height: 12).overlay(Color.white.opacity(0.1))
                miniMetric("Jamaat", "\(s?.totalInJamaat ?? 0)")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private func miniMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Goals

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACTIVE GOALS")
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            if activeGoals.isEmpty {
                Text("No active goals.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeGoals) { goal in
                    goalRow(goal)
                }
            }
        }
    }

    private func goalRow(_ goal: Goal) -> some View {
        let progress = computeGoalProgress(goal)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goalTitle(goal))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(progress)/\(goal.targetValue)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(min(progress, goal.targetValue)),
                         total: Double(max(goal.targetValue, 1)))
                .tint(PrayerStyle.onTime)
        }
        .padding(14)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private func goalTitle(_ goal: Goal) -> String {
        let prayerLabel: String
        if goal.prayerName == "all" { prayerLabel = "All prayers" }
        else { prayerLabel = goal.prayerName }
        let metricLabel: String
        switch goal.metricValue {
        case .completed: metricLabel = "completed"
        case .onTime: metricLabel = "on time"
        case .inJamaat: metricLabel = "in jamaat"
        case .streak: metricLabel = "day streak"
        case .qada: metricLabel = "qada"
        }
        return "\(prayerLabel) — \(metricLabel) (\(goal.periodValue.rawValue))"
    }

    private func computeGoalProgress(_ goal: Goal) -> Int {
        let inRange = allRecords.filter { $0.prayerDate >= goal.startDate }
        let scoped: [PrayerRecord]
        if goal.prayerName == "all" {
            scoped = inRange
        } else {
            scoped = inRange.filter { $0.prayerName == goal.prayerName }
        }
        switch goal.metricValue {
        case .completed: return scoped.filter { $0.prayerStatus != .missed }.count
        case .onTime: return scoped.filter { $0.prayerStatus == .onTime }.count
        case .inJamaat: return scoped.filter { $0.prayedInJamaat }.count
        case .qada: return scoped.filter { $0.prayerStatus == .qada }.count
        case .streak:
            return stats.first(where: { $0.prayerName == UserPrayerStats.overallKey })?.currentStreak ?? 0
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(PreviewContainer.shared)
}
