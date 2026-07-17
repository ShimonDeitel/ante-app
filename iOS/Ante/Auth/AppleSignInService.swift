import Foundation
import Observation
import AuthenticationServices

/// Sign in with Apple. Unlike a habit-tracker app, Ante is mandatory-login:
/// it charges real money and needs an identity to attribute those charges to
/// and to sync stakes/history across the user's own devices, so it does not
/// offer Friction's "continue without an account" escape hatch.
@MainActor
@Observable
final class AppleSignInService {
    private(set) var isSignedIn: Bool
    private(set) var userID: String?
    private(set) var displayName: String?
    var lastError: String?

    private let userIDKey = "ante.appleUserID"
    private let nameKey = "ante.appleDisplayName"

    init() {
        let storedID = UserDefaults.standard.string(forKey: userIDKey)
        userID = storedID
        displayName = UserDefaults.standard.string(forKey: nameKey)
        isSignedIn = storedID != nil
    }

    /// Validate the stored Apple credential on launch. Only a hard `.revoked`
    /// signs the user out - a transient `.notFound` on relaunch must not.
    func refreshCredentialState() async {
        guard let userID else { return }
        let provider = ASAuthorizationAppleIDProvider()
        let state: ASAuthorizationAppleIDProvider.CredentialState = await withCheckedContinuation { continuation in
            provider.getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
        if state == .revoked {
            signOut()
        }
    }

    func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                lastError = "Unexpected credential type."
                return
            }
            userID = credential.user
            UserDefaults.standard.set(credential.user, forKey: userIDKey)
            // fullName is only delivered on the very first authorization.
            if let name = credential.fullName {
                let full = [name.givenName, name.familyName].compactMap { $0 }.joined(separator: " ")
                if !full.isEmpty {
                    displayName = full
                    UserDefaults.standard.set(full, forKey: nameKey)
                }
            }
            isSignedIn = true
            lastError = nil

        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                lastError = nil
            } else {
                lastError = error.localizedDescription
            }
        }
    }

    func signOut() {
        userID = nil
        displayName = nil
        isSignedIn = false
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
    }

    #if DEBUG
    /// The simulator has no Apple ID to authorize against, and UI tests need
    /// a deterministic path through the gate. Never compiled into a Release
    /// build, so it can never reach the App Store binary.
    func devBypass() {
        userID = "DEBUG_BYPASS"
        displayName = "Test User"
        isSignedIn = true
        lastError = nil
    }
    #endif
}
