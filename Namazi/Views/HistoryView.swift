import SwiftUI
import SwiftData

// 52-week GitHub-style heatmap. One cell = one day; color intensity = % of 5 prayers
// completed (missed → faint, all 5 on-time → full teal). Months labeled along the top.
//
// Tap a cell → DayDetailSheet for that date.

struct HistoryView: View {
    @Query(sort: \PrayerRecord.prayerDate) private var allRecords: [PrayerRecord]
    @State private var selectedDay: Date?
    @State private var anchor: Date = Date()

    private let cal = Calendar.namaziGregorian

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    heatmap
                    summaryCards
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .sheet(item: Binding(
            get: { selectedDay.map { DateID(date: $0) } },
            set: { selectedDay = $0?.date }
        )) { id in
            DayDetailSheet(day: id.date, records: recordsFor(day: id.date))
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("History")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Last 52 weeks · tap a day for details")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    // MARK: - Heatmap grid

    private var heatmap: some View {
        let days = buildDays()
        let columns = chunked(days, into: 7) // by week column
        let weekColumns = transposeToWeeks(days)

        return VStack(alignment: .leading, spacing: 8) {
            // Month labels along the top
            monthLabels(columns: columns)

            HStack(alignment: .top, spacing: 4) {
                // Weekday labels
                VStack(spacing: 3) {
                    ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { d in
                        Text(d)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .frame(width: 12, height: 12)
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(weekColumns.indices, id: \.self) { col in
                            VStack(spacing: 3) {
                                ForEach(weekColumns[col], id: \.date) { entry in
                                    cellFor(entry: entry)
                                }
                            }
                        }
                    }
                }
            }
            legend
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private func cellFor(entry: DayEntry) -> some View {
        let fill: Color
        if entry.isPlaceholder {
            fill = Color.clear
        } else if entry.completed == 0 {
            fill = PrayerStyle.pending
        } else {
            let intensity = Double(entry.completed) / 5.0
            fill = PrayerStyle.onTime.opacity(0.25 + intensity * 0.75)
        }
        return RoundedRectangle(cornerRadius: 2.5)
            .fill(fill)
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 2.5)
                    .stroke(entry.isToday ? Color.white : Color.clear, lineWidth: 1)
            )
            .onTapGesture {
                if !entry.isPlaceholder { selectedDay = entry.date }
            }
    }

    private func monthLabels(columns: [[DayEntry]]) -> some View {
        // Approximate: show month names at the columns where a new month starts
        var labels: [(label: String, weekIndex: Int)] = []
        var lastMonth: Int = -1
        let weeks = transposeToWeeks(columns.flatMap { $0 })
        for (idx, week) in weeks.enumerated() {
            if let first = week.first(where: { !$0.isPlaceholder }) {
                let month = cal.component(.month, from: first.date)
                if month != lastMonth {
                    labels.append((PrayerFormat.monthShort.string(from: first.date), idx))
                    lastMonth = month
                }
            }
        }
        return HStack(alignment: .center, spacing: 3) {
            // Empty space for weekday labels column
            Color.clear.frame(width: 12, height: 10)
            ZStack(alignment: .leading) {
                Color.clear.frame(height: 10)
                ForEach(labels, id: \.weekIndex) { item in
                    Text(item.label)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .offset(x: CGFloat(item.weekIndex) * 15)
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 6) {
            Text("Less").font(.caption2).foregroundStyle(.secondary)
            ForEach([0.15, 0.35, 0.55, 0.75, 1.0], id: \.self) { intensity in
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(PrayerStyle.onTime.opacity(intensity))
                    .frame(width: 10, height: 10)
            }
            Text("More").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.top, 6)
    }

    // MARK: - Summary cards

    private var summaryCards: some View {
        let cards = computeSummary()
        return VStack(spacing: 10) {
            ForEach(cards, id: \.title) { card in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(card.value)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text(card.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: card.symbol)
                        .font(.system(size: 28))
                        .foregroundStyle(card.color)
                }
                .padding(16)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Data helpers

    private struct DayEntry {
        let date: Date
        let completed: Int
        let isToday: Bool
        let isPlaceholder: Bool
    }

    private func buildDays() -> [DayEntry] {
        let today = cal.startOfDay(for: Date())
        let start = cal.date(byAdding: .day, value: -364, to: today)!
        let recordsByDay = Dictionary(grouping: allRecords) { cal.startOfDay(for: $0.prayerDate) }

        // Pad so the heatmap starts on Sunday
        let startWeekday = cal.component(.weekday, from: start) - 1 // 0 = Sunday
        var result: [DayEntry] = []
        for _ in 0..<startWeekday {
            result.append(DayEntry(date: start, completed: 0, isToday: false, isPlaceholder: true))
        }
        for offset in 0...364 {
            let d = cal.date(byAdding: .day, value: offset, to: start)!
            let prayed = (recordsByDay[d] ?? []).filter { $0.prayerStatus != .missed }
            var unique = Set<String>()
            for r in prayed {
                let key = r.prayer == .jumuah ? PrayerName.dhuhr.rawValue : r.prayerName
                unique.insert(key)
            }
            result.append(DayEntry(
                date: d,
                completed: unique.count,
                isToday: cal.isDate(d, inSameDayAs: today),
                isPlaceholder: false
            ))
        }
        return result
    }

    private func chunked(_ days: [DayEntry], into size: Int) -> [[DayEntry]] {
        stride(from: 0, to: days.count, by: size).map {
            Array(days[$0..<min($0 + size, days.count)])
        }
    }

    private func transposeToWeeks(_ days: [DayEntry]) -> [[DayEntry]] {
        chunked(days, into: 7)
    }

    private func recordsFor(day: Date) -> [PrayerRecord] {
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return allRecords.filter { $0.prayerDate >= start && $0.prayerDate < end }
    }

    // Summary card model
    private struct SummaryCard {
        let title: String
        let value: String
        let subtitle: String
        let symbol: String
        let color: Color
    }

    private func computeSummary() -> [SummaryCard] {
        let total = allRecords.count
        let completed = allRecords.filter { $0.prayerStatus != .missed }.count
        let onTime = allRecords.filter { $0.prayerStatus == .onTime }.count
        let jamaat = allRecords.filter { $0.prayedInJamaat }.count
        let qada = allRecords.filter { $0.prayerStatus == .qada }.count

        let completionPct = total == 0 ? 0 : Int(Double(completed) / Double(total) * 100)
        let onTimePct = completed == 0 ? 0 : Int(Double(onTime) / Double(completed) * 100)

        return [
            SummaryCard(
                title: "Completion",
                value: "\(completionPct)%",
                subtitle: "\(completed) of \(total) prayers",
                symbol: "checkmark.circle.fill",
                color: PrayerStyle.onTime
            ),
            SummaryCard(
                title: "On-time rate",
                value: "\(onTimePct)%",
                subtitle: "Of completed prayers",
                symbol: "clock.fill",
                color: PrayerStyle.upcoming
            ),
            SummaryCard(
                title: "Jamaat",
                value: "\(jamaat)",
                subtitle: "Congregational prayers",
                symbol: "person.3.fill",
                color: PrayerStyle.inJamaat
            ),
            SummaryCard(
                title: "Qada",
                value: "\(qada)",
                subtitle: "Makeup prayers logged",
                symbol: "arrow.uturn.backward.circle.fill",
                color: PrayerStyle.late
            )
        ]
    }
}

// Identifiable wrapper so we can drive `.sheet(item:)` from a Date
private struct DateID: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewContainer.shared)
}
