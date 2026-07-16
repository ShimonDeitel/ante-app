import Vision
import UIKit

enum BedPhotoVerifier {
    /// FeaturePrintObservation.distance(to:) is a Euclidean distance between
    /// feature vectors -- lower means more visually similar. There's no
    /// universal "same scene" cutoff from Apple; this threshold is a
    /// starting point tuned for "same room, bed now visibly made" and should
    /// be adjusted from real usage, not treated as exact science. It's
    /// exposed here as a single constant for that reason.
    static let similarityThreshold: Double = 0.7

    struct Result {
        let distance: Double
        var passed: Bool { distance <= similarityThreshold }
    }

    static func compare(referenceImage: UIImage, candidateImage: UIImage) async throws -> Result {
        guard let referenceCG = referenceImage.cgImage, let candidateCG = candidateImage.cgImage else {
            throw VerificationError.invalidImage
        }
        let request = GenerateImageFeaturePrintRequest()
        async let referencePrint = request.perform(on: referenceCG)
        async let candidatePrint = request.perform(on: candidateCG)
        let (reference, candidate) = try await (referencePrint, candidatePrint)
        let distance = try reference.distance(to: candidate)
        return Result(distance: distance)
    }

    enum VerificationError: Error {
        case invalidImage
    }
}
