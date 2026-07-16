import SwiftUI

private struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            )
    }
}

extension View {
    /// Tapping anywhere in this view -- background included -- collapses
    /// whatever keyboard/numeric pad is currently up. Verified interactively,
    /// not just compiled: a plain `.onTapGesture` alone will not fire if the
    /// tap lands on another interactive control, which is why this uses
    /// `simultaneousGesture` instead.
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
