import Foundation
import SwiftData

@Model
final class RakatRecord {
    var id: UUID = UUID()
    var prayerRecord: PrayerRecord?

    var rakahNumber: Int = 1
    var type: String = RakatType.fard.rawValue

    var startedAt: Date?
    var durationSeconds: Int?

    @Relationship(deleteRule: .cascade, inverse: \SurahRecitation.rakatRecord)
    var surahRecitations: [SurahRecitation]? = []

    @Relationship(deleteRule: .cascade, inverse: \PostureEvent.rakatRecord)
    var postureEvents: [PostureEvent]? = []

    init(
        id: UUID = UUID(),
        rakahNumber: Int,
        type: RakatType = .fard,
        startedAt: Date? = nil,
        durationSeconds: Int? = nil
    ) {
        self.id = id
        self.rakahNumber = rakahNumber
        self.type = type.rawValue
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
    }
}

extension RakatRecord {
    var rakatType: RakatType {
        get { RakatType(rawValue: type) ?? .fard }
        set { type = newValue.rawValue }
    }
}
