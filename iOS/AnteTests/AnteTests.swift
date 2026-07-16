import Testing
import Foundation
@testable import Ante

struct MoneyFormattingTests {
    @Test func wholeDollarsHaveNoDecimals() {
        #expect(Money.format(cents: 500) == "$5")
    }

    @Test func fractionalCentsShowTwoDecimals() {
        #expect(Money.format(cents: 550) == "$5.50")
    }

    @Test func largeAmountsFormat() {
        #expect(Money.format(cents: 100_000) == "$1,000")
    }
}

struct MorningRecordTests {
    @Test func totalChargedCombinesFineAndSnooze() {
        let record = MorningRecord(outcome: .paidFine, fineChargedCents: 500, snoozeCount: 2, snoozeChargedCents: 200)
        #expect(record.totalChargedCents == 700)
    }

    @Test func verifiedRecordDefaultsToZeroCharge() {
        let record = MorningRecord(outcome: .verified)
        #expect(record.totalChargedCents == 0)
    }
}

struct BedPhotoVerifierResultTests {
    @Test func distanceAtOrBelowThresholdPasses() {
        let result = BedPhotoVerifier.Result(distance: BedPhotoVerifier.similarityThreshold)
        #expect(result.passed)
    }

    @Test func distanceAboveThresholdFails() {
        let result = BedPhotoVerifier.Result(distance: BedPhotoVerifier.similarityThreshold + 0.01)
        #expect(!result.passed)
    }
}

@MainActor
@Suite(.serialized)
struct AppSettingsTests {
    @Test func fineDollarsRoundTripsThroughCents() {
        let settings = AppSettings.load()
        settings.fineDollars = 12
        #expect(settings.fineCents == 1200)
        #expect(settings.fineDollars == 12)
    }

    @Test func fineDollarsHasAOneDollarFloor() {
        let settings = AppSettings.load()
        settings.fineDollars = 0
        #expect(settings.fineCents == 100)
    }

    @Test func snoozeCostCanBeZero() {
        let settings = AppSettings.load()
        settings.snoozeCostDollars = 0
        #expect(settings.snoozeCostCents == 0)
    }
}

struct NextFireTests {
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    @Test func firesLaterTodayWhenTimeAhead() {
        // Wednesday 2026-07-15, 06:00. Alarm 07:00 every day.
        let now = date(2026, 7, 15, 6, 0)
        let next = NextFire.next(hour: 7, minute: 0, weekdayRawValues: [], after: now, calendar: calendar)
        #expect(next == date(2026, 7, 15, 7, 0))
    }

    @Test func rollsToTomorrowWhenTimePassed() {
        let now = date(2026, 7, 15, 8, 0)
        let next = NextFire.next(hour: 7, minute: 0, weekdayRawValues: [], after: now, calendar: calendar)
        #expect(next == date(2026, 7, 16, 7, 0))
    }

    @Test func skipsToNextAllowedWeekday() {
        // 2026-07-15 is a Wednesday; only Mondays allowed -> 2026-07-20.
        let now = date(2026, 7, 15, 8, 0)
        let next = NextFire.next(hour: 7, minute: 0, weekdayRawValues: ["monday"], after: now, calendar: calendar)
        #expect(next == date(2026, 7, 20, 7, 0))
    }

    @Test func sameDayAllowedWeekdayBeforeTime() {
        // Wednesday, only Wednesdays allowed, time still ahead.
        let now = date(2026, 7, 15, 6, 0)
        let next = NextFire.next(hour: 7, minute: 0, weekdayRawValues: ["wednesday"], after: now, calendar: calendar)
        #expect(next == date(2026, 7, 15, 7, 0))
    }
}

struct MockPaymentProcessorTests {
    @Test func chargeReturnsSandboxReceiptForRequestedAmount() async throws {
        let processor = MockPaymentProcessor()
        let receipt = try await processor.charge(amountCents: 750, reason: "Test")
        #expect(receipt.amountCents == 750)
        #expect(receipt.isSandbox)
    }
}
