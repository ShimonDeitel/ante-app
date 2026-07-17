import Foundation

/// Fixed stakes only - no continuous slider. Keeps the "how much is this
/// worth to me" decision fast and deliberate instead of a fiddly drag.
enum MoneyPreset {
    static let fineCents: [Int] = [100, 300, 500, 1_000, 2_000, 5_000, 10_000, 100_000, 1_000_000]
    static let snoozeCostCents: [Int] = [0, 100, 300, 500, 1_000, 2_000, 5_000, 10_000, 100_000, 1_000_000]
}
