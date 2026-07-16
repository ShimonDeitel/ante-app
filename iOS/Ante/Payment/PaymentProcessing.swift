import Foundation

struct Receipt: Identifiable, Codable {
    let id: UUID
    let amountCents: Int
    let reason: String
    let date: Date
    let isSandbox: Bool
}

enum PaymentError: Error, LocalizedError {
    case notConfigured
    case declined
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Payments aren't set up yet."
        case .declined: "The charge was declined."
        case .cancelled: "Cancelled."
        }
    }
}

/// Ante charges real money as the consequence for skipping the morning task
/// or for snoozing, so this is a real payment processor, not an Apple IAP
/// unlock -- the money isn't buying digital content, it's a self-imposed
/// forfeit for a real-world commitment (bed made, camera check), the same
/// category Apple's guidelines carve out for services performed outside the
/// app. `MockPaymentProcessor` is wired in until a live processor account
/// exists; every charge it "settles" is clearly labeled a sandbox charge in
/// the UI and in History so nobody mistakes it for a real one.
protocol PaymentProcessing {
    var isLive: Bool { get }
    func charge(amountCents: Int, reason: String) async throws -> Receipt
}
