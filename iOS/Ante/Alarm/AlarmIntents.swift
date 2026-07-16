import AlarmKit
import AppIntents
import Foundation

/// Metadata attached to every Ante alarm. AlarmKit requires this to conform
/// to Decodable, Encodable, Hashable, Sendable (via AlarmMetadata) so it can
/// be persisted by the system across the alarm's lifecycle.
struct AnteAlarmMetadata: AlarmMetadata {
    var label: String
}

/// Bound to the alert's secondary button ("I'm Up"). AlarmKit's stop button
/// is provided by the system and can't be removed or gated - Apple always
/// lets a ringing alarm be silenced. Tapping this both opens the app AND
/// durably records that a bed check is now owed, so the demand survives the
/// alarm leaving its alerting state, the app being killed, or the phone
/// rebooting. The debt is cleared only by a passing photo or a paid fine.
struct WakeCheckIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "I'm Up"
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        SharedStore.verificationRequested = true
        return .result()
    }
}

/// Bound to the alert's system-provided stop button. Tapping it always
/// silences the alarm - that's an AlarmKit guarantee, not something Ante can
/// override. What Ante *can* control is the consequence: if the bed photo
/// was never verified for this cycle, this intent records a pending
/// settlement so the very next time the app is opened, it blocks on a
/// "pay the fine" screen before anything else.
struct StopWithoutVerifyingIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop"

    @Parameter(title: "Alarm ID")
    var alarmIDString: String

    @Parameter(title: "Fine Amount Cents")
    var fineCents: Int

    init() {
        alarmIDString = ""
        fineCents = 0
    }

    init(alarmID: UUID, fineCents: Int) {
        self.alarmIDString = alarmID.uuidString
        self.fineCents = fineCents
    }

    func perform() async throws -> some IntentResult {
        // The app stopping an already-verified alarm must not create a debt.
        if let verified = SharedStore.lastVerifiedAt, Date().timeIntervalSince(verified) < 120 {
            return .result()
        }
        // Fail SAFE, not silent: if the parameter round-trip through the
        // system lost our values, fall back to the live settings rather than
        // letting the user off free.
        let alarmID = UUID(uuidString: alarmIDString) ?? SharedStore.currentAlarmID ?? UUID()
        let cents = fineCents > 0 ? fineCents : SharedStore.fineCents
        SharedStore.pendingSettlement = SharedStore.PendingSettlement(
            alarmID: alarmID,
            reason: .stoppedWithoutVerifying,
            amountCents: cents,
            createdAt: Date()
        )
        return .result()
    }
}
