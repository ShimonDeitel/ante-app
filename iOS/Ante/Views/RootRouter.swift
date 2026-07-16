import SwiftUI

struct RootRouter: View {
    @Environment(AlarmEngine.self) private var alarmEngine
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase

    @State private var pendingSettlement: SharedStore.PendingSettlement?

    var body: some View {
        ZStack {
            AnteTheme.feltGradient.ignoresSafeArea()

            #if DEBUG
            // Screenshot/debug router: SIMCTL_CHILD_ANTE_SCREEN=home|verify|settle
            switch ProcessInfo.processInfo.environment["ANTE_SCREEN"] {
            case "home":
                HomeView()
            case "verify":
                VerificationFlowView()
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
        .fullScreenCover(isPresented: verificationBinding) {
            VerificationFlowView()
        }
        .fullScreenCover(item: $pendingSettlement) { settlement in
            PayToDismissView(settlement: settlement) {
                pendingSettlement = nil
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                refreshBlockingState()
            }
        }
    }

    @ViewBuilder
    private var routedContent: some View {
        if !settings.onboardingComplete {
            OnboardingView()
        } else {
            HomeView()
        }
    }

    private var verificationBinding: Binding<Bool> {
        Binding(
            get: { alarmEngine.isAlerting && pendingSettlement == nil },
            set: { _ in }
        )
    }

    private func refreshBlockingState() {
        pendingSettlement = SharedStore.pendingSettlement
    }
}

extension SharedStore.PendingSettlement: Identifiable {
    var id: UUID { alarmID }
}
