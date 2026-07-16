import Foundation

/// Not wired up yet. Turning this on needs, in order:
///
/// 1. A Stripe account (real business/bank details -- owner has to create
///    this, it's a login/KYC wall no agent can cross).
/// 2. A thin backend (a Cloudflare Worker, matching how every other Ante-
///    adjacent app in this codebase keeps secrets server-side) that holds
///    the Stripe *secret* key and exposes one endpoint: create a
///    PaymentIntent for a given amount and return its client secret. The
///    secret key must never ship inside the app binary.
/// 3. The StripePaymentSheet Swift package added to project.yml, and this
///    type calling it with the client secret from step 2.
///
/// Until then, `PaymentProcessor.current` stays pointed at
/// `MockPaymentProcessor` and every charge in the app is clearly labeled a
/// sandbox charge.
final class StripePaymentProcessor: PaymentProcessing {
    let isLive = true

    private let backendBaseURL: URL?

    init(backendBaseURL: URL? = nil) {
        self.backendBaseURL = backendBaseURL
    }

    func charge(amountCents: Int, reason: String) async throws -> Receipt {
        guard backendBaseURL != nil else {
            throw PaymentError.notConfigured
        }
        // Intentionally unimplemented until the backend above exists.
        throw PaymentError.notConfigured
    }
}

enum PaymentProcessor {
    /// Single switch point for the whole app. Flip this once Stripe is live.
    static let current: PaymentProcessing = MockPaymentProcessor()
}
