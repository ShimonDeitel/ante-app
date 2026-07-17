import SwiftUI
import AuthenticationServices

/// Shown if Apple revokes the sign-in credential after onboarding already
/// completed (account deleted, credential revoked from Apple ID settings,
/// etc.) - re-blocks until the user re-authenticates.
struct SignInRequiredView: View {
    @Environment(AppleSignInService.self) private var auth
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AnteTheme.feltGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundStyle(AnteTheme.gold)
                Text("Sign in again")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AnteTheme.cream)
                Text("Your Apple sign-in expired or was revoked. Sign in again to keep using Ante.")
                    .font(.subheadline)
                    .foregroundStyle(AnteTheme.cream.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                SignInWithAppleButton(.signIn) { request in
                    auth.configureRequest(request)
                } onCompletion: { result in
                    auth.handle(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .clipShape(.capsule)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }
}
