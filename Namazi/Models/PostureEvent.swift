import Foundation
import SwiftData

// No `endedAt` field — derive as `startedAt + durationSeconds` when needed.

@Model
final class PostureEvent {
    var id: UUID = UUID()
    var prayerRecord: PrayerRecord?
    var rakatRecord: RakatRecord?

    var posture: String = PostureType.qiyam.rawValue
    var startedAt: Date = Date()
    var durationSeconds: Int = 0
    /// Denormalised from RakatRecord so per-rakat aggregations don't need a join.
    var rakahNumber: Int = 1
    /// Raw gyroscope reading — kept verbatim so the detection algorithm can be retuned later.
    var pitchAngleDegrees: Double = 0
    var detectionSource: String = PostureDetectionSource.watchAuto.rawValue

    init(
        id: UUID = UUID(),
        posture: PostureType,
        startedAt: Date,
        durationSeconds: Int,
        rakahNumber: Int,
        pitchAngleDegrees: Double,
        detectionSource: PostureDetectionSource = .watchAuto
    ) {
        self.id = id
        self.posture = posture.rawValue
        self.startedAt = startedAt
        self.durationSeconds = durationSeconds
        self.rakahNumber = rakahNumber
        self.pitchAngleDegrees = pitchAngleDegrees
        self.detectionSource = detectionSource.rawValue
    }
}

extension PostureEvent {
    var postureType: PostureType {
        get { PostureType(rawValue: posture) ?? .qiyam }
        set { posture = newValue.rawValue }
    }

    var detection: PostureDetectionSource {
        get { PostureDetectionSource(rawValue: detectionSource) ?? .watchAuto }
        set { detectionSource = newValue.rawValue }
    }
}
