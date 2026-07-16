import Foundation

/// Backed by an App Group suite so state written from an AlarmKit intent
/// (which may run out-of-process from the main app) is visible the next
/// time the app comes to the foreground.
enum SharedStore {
    static let suiteName = "group.com.shimondeitel.ante"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    private enum Key {
        static let wakeHour = "wakeHour"
        static let wakeMinute = "wakeMinute"
        static let repeatWeekdays = "repeatWeekdays"
        static let fineCents = "fineCents"
        static let snoozeCostCents = "snoozeCostCents"
        static let snoozeMinutes = "snoozeMinutes"
        static let onboardingComplete = "onboardingComplete"
        static let hasReferencePhoto = "hasReferencePhoto"
        static let currentAlarmID = "currentAlarmID"
        static let pendingSettlement = "pendingSettlement"
    }

    // MARK: - Settings

    static var wakeHour: Int {
        get { defaults.object(forKey: Key.wakeHour) as? Int ?? 7 }
        set { defaults.set(newValue, forKey: Key.wakeHour) }
    }

    static var wakeMinute: Int {
        get { defaults.object(forKey: Key.wakeMinute) as? Int ?? 0 }
        set { defaults.set(newValue, forKey: Key.wakeMinute) }
    }

    /// Locale.Weekday raw values ("sunday", "monday", ...). Defaults to every day.
    static var repeatWeekdayRawValues: [String] {
        get {
            defaults.array(forKey: Key.repeatWeekdays) as? [String]
                ?? ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        }
        set { defaults.set(newValue, forKey: Key.repeatWeekdays) }
    }

    static var fineCents: Int {
        get { defaults.object(forKey: Key.fineCents) as? Int ?? 500 }
        set { defaults.set(newValue, forKey: Key.fineCents) }
    }

    static var snoozeCostCents: Int {
        get { defaults.object(forKey: Key.snoozeCostCents) as? Int ?? 100 }
        set { defaults.set(newValue, forKey: Key.snoozeCostCents) }
    }

    static var snoozeMinutes: Int {
        get { defaults.object(forKey: Key.snoozeMinutes) as? Int ?? 9 }
        set { defaults.set(newValue, forKey: Key.snoozeMinutes) }
    }

    static var onboardingComplete: Bool {
        get { defaults.bool(forKey: Key.onboardingComplete) }
        set { defaults.set(newValue, forKey: Key.onboardingComplete) }
    }

    static var hasReferencePhoto: Bool {
        get { defaults.bool(forKey: Key.hasReferencePhoto) }
        set { defaults.set(newValue, forKey: Key.hasReferencePhoto) }
    }

    static var currentAlarmID: UUID? {
        get { (defaults.string(forKey: Key.currentAlarmID)).flatMap(UUID.init) }
        set { defaults.set(newValue?.uuidString, forKey: Key.currentAlarmID) }
    }

    // MARK: - Pending settlement

    /// Written by the alarm's stop/secondary App Intents (which may run without
    /// opening the app) whenever an alarm cycle ends without a verified bed
    /// photo. The app checks this on every foreground and blocks all other
    /// screens until it's resolved (task done retroactively is not accepted -
    /// the fine is owed; the user pays it here).
    struct PendingSettlement: Codable {
        var alarmID: UUID
        var reason: Reason
        var amountCents: Int
        var createdAt: Date

        enum Reason: String, Codable {
            case stoppedWithoutVerifying
            case snoozeRequested
        }
    }

    static var pendingSettlement: PendingSettlement? {
        get {
            guard let data = defaults.data(forKey: Key.pendingSettlement) else { return nil }
            return try? JSONDecoder().decode(PendingSettlement.self, from: data)
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: Key.pendingSettlement)
                return
            }
            defaults.set(try? JSONEncoder().encode(newValue), forKey: Key.pendingSettlement)
        }
    }
}
