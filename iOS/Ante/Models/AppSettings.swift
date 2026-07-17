import Foundation
import Observation

/// UI-facing mirror of SharedStore. Reads/writes go straight through so the
/// AlarmKit intents (which touch SharedStore directly, not this class) never
/// see stale values.
@Observable
final class AppSettings {
    var wakeHour: Int {
        didSet { SharedStore.wakeHour = wakeHour }
    }
    var wakeMinute: Int {
        didSet { SharedStore.wakeMinute = wakeMinute }
    }
    var repeatWeekdayRawValues: [String] {
        didSet { SharedStore.repeatWeekdayRawValues = repeatWeekdayRawValues }
    }
    var fineCents: Int {
        didSet { SharedStore.fineCents = fineCents }
    }
    var snoozeCostCents: Int {
        didSet { SharedStore.snoozeCostCents = snoozeCostCents }
    }
    var snoozeMinutes: Int {
        didSet { SharedStore.snoozeMinutes = snoozeMinutes }
    }
    var taskType: TaskType {
        didSet { SharedStore.taskType = taskType }
    }
    var onboardingComplete: Bool {
        didSet { SharedStore.onboardingComplete = onboardingComplete }
    }
    var hasAgreedToTerms: Bool {
        didSet { SharedStore.hasAgreedToTerms = hasAgreedToTerms }
    }

    private init(
        wakeHour: Int, wakeMinute: Int, repeatWeekdayRawValues: [String],
        fineCents: Int, snoozeCostCents: Int, snoozeMinutes: Int, taskType: TaskType,
        onboardingComplete: Bool, hasAgreedToTerms: Bool
    ) {
        self.wakeHour = wakeHour
        self.wakeMinute = wakeMinute
        self.repeatWeekdayRawValues = repeatWeekdayRawValues
        self.fineCents = fineCents
        self.snoozeCostCents = snoozeCostCents
        self.snoozeMinutes = snoozeMinutes
        self.taskType = taskType
        self.onboardingComplete = onboardingComplete
        self.hasAgreedToTerms = hasAgreedToTerms
    }

    static func load() -> AppSettings {
        AppSettings(
            wakeHour: SharedStore.wakeHour,
            wakeMinute: SharedStore.wakeMinute,
            repeatWeekdayRawValues: SharedStore.repeatWeekdayRawValues,
            fineCents: SharedStore.fineCents,
            snoozeCostCents: SharedStore.snoozeCostCents,
            snoozeMinutes: SharedStore.snoozeMinutes,
            taskType: SharedStore.taskType,
            onboardingComplete: SharedStore.onboardingComplete,
            hasAgreedToTerms: SharedStore.hasAgreedToTerms
        )
    }

    /// Snapshot for iCloud sync (CloudSync.swift). Kept separate from the
    /// @Observable class itself since Codable + @Observable macro storage
    /// don't mix cleanly, and CloudSync needs a plain value type to diff/merge.
    struct Snapshot: Codable {
        var wakeHour: Int
        var wakeMinute: Int
        var repeatWeekdayRawValues: [String]
        var fineCents: Int
        var snoozeCostCents: Int
        var snoozeMinutes: Int
        var taskType: TaskType
    }

    var snapshot: Snapshot {
        Snapshot(
            wakeHour: wakeHour, wakeMinute: wakeMinute,
            repeatWeekdayRawValues: repeatWeekdayRawValues,
            fineCents: fineCents, snoozeCostCents: snoozeCostCents,
            snoozeMinutes: snoozeMinutes, taskType: taskType
        )
    }

    func apply(_ snapshot: Snapshot) {
        wakeHour = snapshot.wakeHour
        wakeMinute = snapshot.wakeMinute
        repeatWeekdayRawValues = snapshot.repeatWeekdayRawValues
        fineCents = snapshot.fineCents
        snoozeCostCents = snapshot.snoozeCostCents
        snoozeMinutes = snapshot.snoozeMinutes
        taskType = snapshot.taskType
    }
}
