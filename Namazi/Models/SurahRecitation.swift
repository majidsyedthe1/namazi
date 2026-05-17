import Foundation
import SwiftData

@Model
final class SurahRecitation {
    var id: UUID = UUID()
    var rakatRecord: RakatRecord?

    var surahNumber: Int = 1
    var surahName: String = ""
    var orderInRakat: Int = 1
    var isFullSurah: Bool = true
    var ayahStart: Int?
    var ayahEnd: Int?

    init(
        id: UUID = UUID(),
        surahNumber: Int,
        surahName: String,
        orderInRakat: Int = 1,
        isFullSurah: Bool = true,
        ayahStart: Int? = nil,
        ayahEnd: Int? = nil
    ) {
        self.id = id
        self.surahNumber = surahNumber
        self.surahName = surahName
        self.orderInRakat = orderInRakat
        self.isFullSurah = isFullSurah
        self.ayahStart = ayahStart
        self.ayahEnd = ayahEnd
    }
}
