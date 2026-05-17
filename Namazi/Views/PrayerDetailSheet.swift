import SwiftUI
import SwiftData

// Detail sheet for a single PrayerRecord — shows timing, posture timeline (if Watch),
// surahs recited, location, notes.

struct PrayerDetailSheet: View {
    let record: PrayerRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    timingCard
                    if record.prayerSource == .watch {
                        posturesSection
                        surahsSection
                    }
                    contextSection
                    if let notes = record.notes, !notes.isEmpty {
                        notesSection(text: notes)
                    }
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: record.prayer.symbol)
                .font(.system(size: 28))
                .foregroundStyle(record.prayerStatus.color)
                .frame(width: 52, height: 52)
                .background(record.prayerStatus.color.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(record.prayer.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(record.prayerStatus.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(record.prayerStatus.color)
            }
            Spacer()
        }
    }

    // MARK: - Timing

    private var timingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Timing")
            VStack(spacing: 12) {
                if let start = record.startedAt {
                    timingRow(label: "Started", value: PrayerFormat.time.string(from: start))
                }
                if let end = record.endedAt {
                    timingRow(label: "Ended", value: PrayerFormat.time.string(from: end))
                }
                if let dur = record.durationSeconds {
                    timingRow(label: "Duration", value: PrayerFormat.duration(seconds: dur))
                }
                if let ws = record.windowStart, let we = record.windowEnd {
                    timingRow(
                        label: "Window",
                        value: "\(PrayerFormat.time.string(from: ws)) – \(PrayerFormat.time.string(from: we))"
                    )
                }
                timingRow(label: "Rakats", value: "\(record.rakats)")
            }
            .padding(16)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func timingRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(.white).fontWeight(.medium)
        }
        .font(.subheadline)
    }

    // MARK: - Posture timeline

    private var posturesSection: some View {
        let postures = (record.postureEvents ?? []).sorted { $0.startedAt < $1.startedAt }
        return VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Posture timeline")
            if postures.isEmpty {
                Text("No posture data recorded.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                postureBars(postures: postures)
                postureLegend
            }
        }
    }

    private func postureBars(postures: [PostureEvent]) -> some View {
        // Build a row per rakah
        let grouped = Dictionary(grouping: postures, by: { $0.rakahNumber })
        let sortedKeys = grouped.keys.sorted()
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(sortedKeys, id: \.self) { rakah in
                let row = grouped[rakah] ?? []
                let total = row.map { $0.durationSeconds }.reduce(0, +)
                HStack(spacing: 8) {
                    Text("R\(rakah)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, alignment: .leading)
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            ForEach(row) { event in
                                Rectangle()
                                    .fill(colorFor(event.postureType))
                                    .frame(width: max(2, geo.size.width * CGFloat(event.durationSeconds) / CGFloat(max(total, 1))))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .frame(height: 18)
                    Text(PrayerFormat.duration(seconds: total))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
    }

    private var postureLegend: some View {
        HStack(spacing: 12) {
            ForEach(PostureType.allCases, id: \.self) { p in
                HStack(spacing: 4) {
                    Circle().fill(colorFor(p)).frame(width: 8, height: 8)
                    Text(p.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func colorFor(_ posture: PostureType) -> Color {
        switch posture {
        case .qiyam: return PrayerStyle.upcoming
        case .ruku: return PrayerStyle.onTime
        case .sajda: return PrayerStyle.inJamaat
        case .jalsa: return PrayerStyle.late
        case .tashahhud: return Color.cyan
        }
    }

    // MARK: - Surahs

    private var surahsSection: some View {
        let recitations = (record.rakatRecords ?? [])
            .sorted { $0.rakahNumber < $1.rakahNumber }
            .flatMap { rakat in (rakat.surahRecitations ?? []).map { (rakat.rakahNumber, $0) } }

        return VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Surahs recited")
            if recitations.isEmpty {
                Text("No surah data recorded.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(recitations.enumerated()), id: \.offset) { _, item in
                        HStack {
                            Text("R\(item.0)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .leading)
                            Text(item.1.surahName)
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Spacer()
                            if item.1.isFullSurah {
                                Text("Full")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else if let a = item.1.ayahStart, let b = item.1.ayahEnd {
                                Text("\(a)–\(b)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Context

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Context")
            VStack(spacing: 12) {
                timingRow(label: "Location", value: record.location.rawValue.capitalized)
                timingRow(label: "Source", value: record.prayerSource.rawValue.capitalized)
                if record.prayedInJamaat {
                    timingRow(label: "Jamaat", value: "Yes")
                }
                if record.isTravelling {
                    timingRow(label: "Travel mode", value: "On")
                }
                if record.isQada, let original = record.qadaForDate {
                    timingRow(
                        label: "Qada for",
                        value: original.formatted(date: .abbreviated, time: .omitted)
                    )
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func notesSection(text: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Notes")
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    PrayerDetailPreviewWrapper()
        .modelContainer(PreviewContainer.shared)
}

private struct PrayerDetailPreviewWrapper: View {
    @Environment(\.modelContext) private var context
    var body: some View {
        let descriptor = FetchDescriptor<PrayerRecord>()
        let any = (try? context.fetch(descriptor))?.first
        return Group {
            if let any {
                PrayerDetailSheet(record: any)
            } else {
                Text("No mock records found").foregroundStyle(.red)
            }
        }
    }
}
