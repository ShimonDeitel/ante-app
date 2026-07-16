import Foundation

/// Pure next-fire-time computation for the daily schedule. The enforcement
/// fallback compares this against "now": if the fire time passed and no
/// resolution (verified / snoozed / paid) happened, the ante is forfeit -
/// no reliance on AlarmKit executing our intents, which it empirically does
/// not do for the system Stop button.
enum NextFire {
    private static let weekdayNumbers: [String: Int] = [
        "sunday": 1, "monday": 2, "tuesday": 3, "wednesday": 4,
        "thursday": 5, "friday": 6, "saturday": 7
    ]

    static func next(
        hour: Int,
        minute: Int,
        weekdayRawValues: [String],
        after: Date,
        calendar: Calendar = .current
    ) -> Date? {
        let allowed = Set(weekdayRawValues.compactMap { weekdayNumbers[$0] })
        for dayOffset in 0..<9 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: after) else { continue }
            var comps = calendar.dateComponents([.year, .month, .day], from: day)
            comps.hour = hour
            comps.minute = minute
            comps.second = 0
            guard let candidate = calendar.date(from: comps), candidate > after else { continue }
            if allowed.isEmpty || allowed.contains(calendar.component(.weekday, from: candidate)) {
                return candidate
            }
        }
        return nil
    }
}
