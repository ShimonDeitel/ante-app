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

struct MoneyPresetTests {
    @Test func finePresetsMatchOwnerSpec() {
        let dollars = MoneyPreset.fineCents.map { $0 / 100 }
        #expect(dollars == [1, 3, 5, 10, 20, 50, 100, 1000, 10000])
    }

    @Test func snoozePresetsIncludeFree() {
        #expect(MoneyPreset.snoozeCostCents.first == 0)
    }
}

struct TaskTypeTests {
    @Test func everyTaskHasANonEmptyVerificationQuestion() {
        for task in TaskType.allCases {
            #expect(!task.verificationQuestion.isEmpty)
            #expect(task.verificationQuestion.uppercased().contains("YES"))
        }
    }
}

@MainActor
@Suite(.serialized)
struct AppSettingsTests {
    @Test func fineCentsMustBeAPreset() {
        let settings = AppSettings.load()
        settings.fineCents = 500
        #expect(MoneyPreset.fineCents.contains(settings.fineCents))
    }

    @Test func snoozeCostCanBeZero() {
        let settings = AppSettings.load()
        settings.snoozeCostCents = 0
        #expect(settings.snoozeCostCents == 0)
    }

    @Test func snapshotRoundTrips() {
        let settings = AppSettings.load()
        settings.fineCents = 1000
        settings.taskType = .touchGrass
        let snapshot = settings.snapshot
        settings.fineCents = 300
        settings.taskType = .makeBed
        settings.apply(snapshot)
        #expect(settings.fineCents == 1000)
        #expect(settings.taskType == .touchGrass)
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
