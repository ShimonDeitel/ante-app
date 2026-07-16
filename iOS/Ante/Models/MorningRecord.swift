import Foundation
import SwiftData

enum MorningOutcome: String, Codable {
    case verified
    case paidFine
}

@Model
final class MorningRecord {
    var date: Date
    var outcome: MorningOutcome
    var fineChargedCents: Int
    var snoozeCount: Int
    var snoozeChargedCents: Int

    init(
        date: Date = Date(),
        outcome: MorningOutcome,
        fineChargedCents: Int = 0,
        snoozeCount: Int = 0,
        snoozeChargedCents: Int = 0
    ) {
        self.date = date
        self.outcome = outcome
        self.fineChargedCents = fineChargedCents
        self.snoozeCount = snoozeCount
        self.snoozeChargedCents = snoozeChargedCents
    }

    var totalChargedCents: Int { fineChargedCents + snoozeChargedCents }
}
