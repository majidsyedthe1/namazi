import SwiftUI

// Shows a single day's 5 prayers with status, timing, and quick stats.
// Reached by tapping a cell on the History heatmap.

struct DayDetailSheet: View {
    let day: Date
    let records: [PrayerRecord]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecord: PrayerRecord?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    summary
                    prayerList
                }
                .padding(20)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $selectedRecord) { record in
            PrayerDetailSheet(record: record)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(PrayerFormat.weekdayLong.string(from: day))
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(daySubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var daySubtitle: String {
        let completed = records.filter { $0.prayerStatus != .missed }.count
        return "\(completed) of 5 prayers completed"
    }

    private var summary: some View {
        let onTime = records.filter { $0.prayerStatus == .onTime }.count
        let late = records.filter { $0.prayerStatus == .late }.count
        let missed = records.filter { $0.prayerStatus == .missed }.count
        let jamaat = records.filter { $0.prayedInJamaat }.count

        return HStack(spacing: 8) {
            mini(value: onTime, label: "On time", color: PrayerStyle.onTime)
            mini(value: late, label: "Late", color: PrayerStyle.late)
            mini(value: missed, label: "Missed", color: PrayerStyle.missed)
            mini(value: jamaat, label: "Jamaat", color: PrayerStyle.inJamaat)
        }
    }

    private func mini(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
    }

    private var prayerList: some View {
        VStack(spacing: 10) {
            ForEach(PrayerName.fiveDaily, id: \.self) { prayer in
                row(for: prayer)
            }
        }
    }

    private func row(for prayer: PrayerName) -> some View {
        let record = records.first(where: {
            $0.prayer == prayer || (prayer == .dhuhr && $0.prayer == .jumuah)
        })
        let lookup = record?.prayer ?? prayer
        return Button {
            if let record { selectedRecord = record }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: lookup.symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(record?.prayerStatus.color ?? PrayerStyle.pending)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(lookup.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let record, let started = record.startedAt {
                        Text(PrayerFormat.time.string(from: started))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if record == nil {
                        Text("Missed").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let record {
                    HStack(spacing: 6) {
                        Circle().fill(record.prayerStatus.color).frame(width: 8, height: 8)
                        Text(record.prayerStatus.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                } else {
                    Image(systemName: "minus")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DayDetailSheet(day: Date(), records: [])
        .modelContainer(PreviewContainer.shared)
}
