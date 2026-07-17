import Foundation
import SwiftData

enum MorningOutcome: String, Codable {
    case verified
    case paidFine
}

@Model
final class MorningRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var outcome: MorningOutcome = MorningOutcome.verified
    var fineChargedCents: Int = 0
    var snoozeCount: Int = 0
    var snoozeChargedCents: Int = 0

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        outcome: MorningOutcome,
        fineChargedCents: Int = 0,
        snoozeCount: Int = 0,
        snoozeChargedCents: Int = 0
    ) {
        self.id = id
        self.date = date
        self.outcome = outcome
        self.fineChargedCents = fineChargedCents
        self.snoozeCount = snoozeCount
        self.snoozeChargedCents = snoozeChargedCents
    }

    var totalChargedCents: Int { fineChargedCents + snoozeChargedCents }

    var cloudEntry: CloudSync.HistoryEntry {
        CloudSync.HistoryEntry(
            id: id, date: date, outcome: outcome.rawValue,
            fineChargedCents: fineChargedCents, snoozeCount: snoozeCount,
            snoozeChargedCents: snoozeChargedCents
        )
    }
}
