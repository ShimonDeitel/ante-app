import Foundation
import SwiftData

/// The one place that actually moves money and writes history, so both the
/// "pay the fine" screen (reached after the system Stop button was tapped)
/// and the in-app "I can't do it, charge me" shortcut stay in sync.
enum SettlementService {
    @discardableResult
    static func chargeFine(
        cents: Int,
        alarmEngine: AlarmEngine,
        settings: AppSettings,
        modelContext: ModelContext
    ) async throws -> Receipt {
        let receipt = try await PaymentProcessor.current.charge(amountCents: cents, reason: "Missed bed check")
        modelContext.insert(MorningRecord(outcome: .paidFine, fineChargedCents: cents))
        SharedStore.pendingSettlement = nil
        SharedStore.verificationRequested = false
        SharedStore.nextFireDate = nil
        try await alarmEngine.rearmDailySchedule(settings: settings)
        return receipt
    }

    static func recordVerified(modelContext: ModelContext) {
        modelContext.insert(MorningRecord(outcome: .verified))
    }

    @discardableResult
    static func chargeSnooze(
        cents: Int,
        alarmEngine: AlarmEngine,
        settings: AppSettings
    ) async throws -> Receipt {
        // The re-ring will demand the bed check again; until then the user
        // has bought their way out of the current demand.
        SharedStore.verificationRequested = false
        guard cents > 0 else {
            try await alarmEngine.snooze(settings: settings)
            return Receipt(id: UUID(), amountCents: 0, reason: "Snooze", date: Date(), isSandbox: true)
        }
        let receipt = try await PaymentProcessor.current.charge(amountCents: cents, reason: "Snooze")
        try await alarmEngine.snooze(settings: settings)
        return receipt
    }
}
