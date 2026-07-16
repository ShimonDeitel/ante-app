import SwiftUI

/// The one screen the app is allowed to block on. Driven by durable
/// SharedStore state written by the alarm's App Intents, never by live
/// AlarmKit state alone - the alert may already be gone by the time the
/// app foregrounds.
enum BlockingScreen: Identifiable, Equatable {
    case settle(SharedStore.PendingSettlement)
    case verify

    var id: String {
        switch self {
        case .settle(let s): "settle-\(s.alarmID.uuidString)"
        case .verify: "verify"
        }
    }

    static func == (lhs: BlockingScreen, rhs: BlockingScreen) -> Bool { lhs.id == rhs.id }
}

struct RootRouter: View {
    @Environment(AlarmEngine.self) private var alarmEngine
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase

    @State private var blocking: BlockingScreen?

    var body: some View {
        ZStack {
            AnteTheme.feltGradient.ignoresSafeArea()

            #if DEBUG
            // Screenshot/debug router: SIMCTL_CHILD_ANTE_SCREEN=home|verify|settle
            switch ProcessInfo.processInfo.environment["ANTE_SCREEN"] {
            case "home":
                HomeView()
            case "verify":
                VerificationFlowView(onResolved: {})
            case "settle":
                PayToDismissView(
                    settlement: .init(alarmID: UUID(), reason: .stoppedWithoutVerifying, amountCents: 2500, createdAt: Date()),
                    onResolved: {}
                )
            default:
                routedContent
            }
            #else
            routedContent
            #endif
        }
        .fullScreenCover(item: $blocking) { screen in
            switch screen {
            case .settle(let settlement):
                PayToDismissView(settlement: settlement) {
                    refreshBlockingState()
                }
            case .verify:
                VerificationFlowView {
                    refreshBlockingState()
                }
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { refreshBlockingState() }
        }
        .onChange(of: alarmEngine.isAlerting) { _, _ in
            refreshBlockingState()
        }
        #if DEBUG
        .task {
            // SIMCTL_CHILD_ANTE_TEST_ALARM=<seconds>: bootstrap a testable
            // cycle (skip onboarding, dummy reference photo, one-shot alarm).
            if let raw = ProcessInfo.processInfo.environment["ANTE_TEST_ALARM"],
               let seconds = TimeInterval(raw) {
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
                let dummy = renderer.image { ctx in
                    UIColor.systemBrown.setFill()
                    ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
                }
                ReferencePhotoStore.save(dummy)
                settings.onboardingComplete = true
                _ = await alarmEngine.requestAuthorizationIfNeeded()
                try? await alarmEngine.scheduleTestAlarm(after: seconds, settings: settings)
            }
        }
        #endif
    }

    @ViewBuilder
    private var routedContent: some View {
        if !settings.onboardingComplete {
            OnboardingView()
        } else {
            HomeView()
        }
    }

    /// Money owed always wins; a demanded or in-progress bed check comes
    /// second. Finally, the deadline fallback: if the scheduled fire time
    /// has passed and nothing resolved the cycle (no verified photo, no
    /// snooze, no payment), the ante is forfeit - computed locally, with no
    /// reliance on AlarmKit running any of our intents (it does not run the
    /// stop intent for its system Stop button). Recomputed on every
    /// foreground and alarm-state change.
    private func refreshBlockingState() {
        guard settings.onboardingComplete else {
            blocking = nil
            return
        }
        if let settlement = SharedStore.pendingSettlement {
            blocking = .settle(settlement)
        } else if SharedStore.verificationRequested || alarmEngine.isAlerting {
            blocking = .verify
        } else if let fire = SharedStore.nextFireDate, Date() >= fire {
            let settlement = SharedStore.PendingSettlement(
                alarmID: SharedStore.currentAlarmID ?? UUID(),
                reason: .stoppedWithoutVerifying,
                amountCents: settings.fineCents,
                createdAt: Date()
            )
            SharedStore.pendingSettlement = settlement
            blocking = .settle(settlement)
        } else {
            blocking = nil
        }
    }
}
