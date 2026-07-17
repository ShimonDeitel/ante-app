import Foundation
import UIKit

enum VisionVerificationError: Error, LocalizedError {
    case invalidImage
    case rateLimited
    case serverError(String)
    case malformedResponse

    var errorDescription: String? {
        switch self {
        case .invalidImage: "Couldn't read that photo."
        case .rateLimited: "Too many checks at once. Wait a moment and try again."
        case .serverError(let message): message
        case .malformedResponse: "Got an unexpected response. Try again."
        }
    }
}

/// Judges a single photo against a task-specific question - no reference
/// photo, no on-device model (Apple's on-device LLM is text-only as of this
/// SDK; verified by inspecting FoundationModels.symbols.json directly, not
/// assumed). Calls the vision-proxy Cloudflare Worker already deployed and
/// used in production by Attic/Postmark: an OpenAI-chat-completions-shaped,
/// unauthenticated, IP-rate-limited proxy in front of Workers AI's
/// @cf/meta/llama-3.2-11b-vision-instruct. No client secret, no new
/// deployment - this reuses the exact same endpoint.
enum CloudVisionVerifier {
    struct Result {
        let passed: Bool
        let rawAnswer: String
    }

    private static let endpoint = URL(string: "https://vision-proxy.s0533495227.workers.dev")!

    static func verify(image: UIImage, taskType: TaskType) async throws -> Result {
        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            throw VisionVerificationError.invalidImage
        }
        let dataURI = "data:image/jpeg;base64,\(jpegData.base64EncodedString())"

        let body: [String: Any] = [
            "messages": [
                [
                    "role": "system",
                    "content": "You are a strict but fair judge of whether a photo satisfies a simple real-world task. Answer only YES or NO, nothing else.",
                ],
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": taskType.verificationQuestion],
                        ["type": "image_url", "image_url": ["url": dataURI]],
                    ],
                ],
            ],
            "temperature": 0.2,
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw VisionVerificationError.malformedResponse
        }
        if http.statusCode == 429 {
            throw VisionVerificationError.rateLimited
        }
        guard http.statusCode == 200 else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
            throw VisionVerificationError.serverError(message ?? "Verification failed (\(http.statusCode)).")
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw VisionVerificationError.malformedResponse
        }

        let normalized = content.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return Result(passed: normalized.contains("YES"), rawAnswer: content)
    }
}
