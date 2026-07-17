import Testing
import UIKit
@testable import Ante

/// Hits the REAL vision-proxy Worker (no mock) to prove the request/response
/// contract implemented in CloudVisionVerifier actually matches what the
/// live, already-in-production endpoint does today. Network-dependent by
/// design - this is the one test in the suite that is allowed to fail if
/// the shared endpoint is down, but a parsing/shape regression here would
/// otherwise go undetected until a real morning.
struct CloudVisionVerifierLiveTests {
    @Test func realEndpointReturnsAParsedYesNoJudgment() async throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
        let solidRedSquare = renderer.image { ctx in
            UIColor.systemRed.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
        }

        let result = try await CloudVisionVerifier.verify(image: solidRedSquare, taskType: .makeBed)

        // A solid red square is obviously not a made bed - the live model
        // should say NO. This asserts the full pipeline (JPEG encode ->
        // base64 data URI -> POST -> choices[0].message.content parse ->
        // YES/NO normalization) actually round-trips against production,
        // not just that it compiles.
        #expect(!result.rawAnswer.isEmpty)
        #expect(!result.passed, "A solid red square should not pass as a made bed; got: \(result.rawAnswer)")
    }
}
