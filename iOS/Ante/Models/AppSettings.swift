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
    var onboardingComplete: Bool {
        didSet { SharedStore.onboardingComplete = onboardingComplete }
    }
    var hasReferencePhoto: Bool {
        didSet { SharedStore.hasReferencePhoto = hasReferencePhoto }
    }

    private init(
        wakeHour: Int, wakeMinute: Int, repeatWeekdayRawValues: [String],
        fineCents: Int, snoozeCostCents: Int, snoozeMinutes: Int,
        onboardingComplete: Bool, hasReferencePhoto: Bool
    ) {
        self.wakeHour = wakeHour
        self.wakeMinute = wakeMinute
        self.repeatWeekdayRawValues = repeatWeekdayRawValues
        self.fineCents = fineCents
        self.snoozeCostCents = snoozeCostCents
        self.snoozeMinutes = snoozeMinutes
        self.onboardingComplete = onboardingComplete
        self.hasReferencePhoto = hasReferencePhoto
    }

    static func load() -> AppSettings {
        AppSettings(
            wakeHour: SharedStore.wakeHour,
            wakeMinute: SharedStore.wakeMinute,
            repeatWeekdayRawValues: SharedStore.repeatWeekdayRawValues,
            fineCents: SharedStore.fineCents,
            snoozeCostCents: SharedStore.snoozeCostCents,
            snoozeMinutes: SharedStore.snoozeMinutes,
            onboardingComplete: SharedStore.onboardingComplete,
            hasReferencePhoto: SharedStore.hasReferencePhoto
        )
    }

    var fineDollars: Double {
        get { Double(fineCents) / 100 }
        set { fineCents = max(100, Int((newValue * 100).rounded())) }
    }

    var snoozeCostDollars: Double {
        get { Double(snoozeCostCents) / 100 }
        set { snoozeCostCents = max(0, Int((newValue * 100).rounded())) }
    }
}
