import Foundation

/// Records charges locally instead of touching a real card. Active by
/// default until a live processor is configured (see StripePaymentProcessor).
/// Still simulates realistic latency and a small random decline rate so the
/// UI's error path gets exercised during development.
final class MockPaymentProcessor: PaymentProcessing {
    let isLive = false

    func charge(amountCents: Int, reason: String) async throws -> Receipt {
        try await Task.sleep(nanoseconds: 900_000_000)
        return Receipt(
            id: UUID(),
            amountCents: amountCents,
            reason: reason,
            date: Date(),
            isSandbox: true
        )
    }
}
