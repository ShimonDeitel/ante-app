import SwiftUI
import AuthenticationServices

private enum OnboardingStep: Int, CaseIterable {
    case welcome, taskType, schedule, stakes, signIn, agree
}

struct OnboardingView: View {
    @Environment(AlarmEngine.self) private var alarmEngine
    @Environment(AppSettings.self) private var settings
    @Environment(AppleSignInService.self) private var auth
    @Environment(\.colorScheme) private var colorScheme

    @State private var step: OnboardingStep = .welcome
    @State private var isStarting = false
    @State private var errorMessage: String?
    @State private var hasCheckedAgree = false

    var body: some View {
        VStack(spacing: 0) {
            stepDots
                .padding(.top, 24)

            Group {
                switch step {
                case .welcome: welcomeStep
                case .taskType: taskTypeStep
                case .schedule: scheduleStep
                case .stakes: stakesStep
                case .signIn: signInStep
                case .agree: agreeStep
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id(step)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
        .dismissKeyboardOnTap()
    }

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.self) { s in
                Capsule()
                    .fill(s == step ? AnteTheme.gold : AnteTheme.gold.opacity(0.25))
                    .frame(width: s == step ? 22 : 8, height: 8)
            }
        }
    }

    // MARK: Steps

    private var welcomeStep: some View {
        StepScaffold(
            title: "Ante",
            subtitle: "You put money on the line to wake up. Complete the task and the ante's returned. Skip it, and it's forfeit.",
            primaryTitle: "Deal me in"
        ) {
            advance()
        } content: {
            VStack(spacing: 20) {
                ChipStackView(chipCount: 5)
                PulsingGlowRing()
                    .frame(width: 90, height: 90)
                    .overlay { Image(systemName: "bed.double.fill").font(.system(size: 30)).foregroundStyle(AnteTheme.gold) }
            }
        }
    }

    private var taskTypeStep: some View {
        StepScaffold(
            title: "Pick your task",
            subtitle: "What you have to prove each morning to keep your ante. Checked by AI, right when you take the photo - no setup photo needed.",
            primaryTitle: "Next"
        ) {
            advance()
        } content: {
            VStack(spacing: 12) {
                ForEach(TaskType.allCases) { task in
                    let isOn = task == settings.taskType
                    Button {
                        settings.taskType = task
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: task.systemImageName)
                                .font(.system(size: 20))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title).font(.headline)
                                Text(task.instruction).font(.caption)
                            }
                            Spacer()
                            if isOn {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .padding(16)
                        .background(isOn ? AnteTheme.gold : AnteTheme.felt)
                        .foregroundStyle(isOn ? AnteTheme.feltDeep : AnteTheme.cream)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var scheduleStep: some View {
        StepScaffold(
            title: "Set the wake time",
            subtitle: "Ante rings every day you select, at this time.",
            primaryTitle: "Next"
        ) {
            advance()
        } content: {
            DatePicker(
                "",
                selection: Binding(
                    get: {
                        Calendar.current.date(from: DateComponents(hour: settings.wakeHour, minute: settings.wakeMinute)) ?? Date()
                    },
                    set: { newValue in
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                        settings.wakeHour = comps.hour ?? 7
                        settings.wakeMinute = comps.minute ?? 0
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .tint(AnteTheme.gold)
        }
    }

    private var stakesStep: some View {
        StepScaffold(
            title: "Set the stakes",
            subtitle: "This is what skipping the task costs you. Higher stakes, harder to hit snooze.",
            primaryTitle: "Next"
        ) {
            advance()
        } content: {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        Text("Fine for skipping")
                            .font(.footnote)
                            .foregroundStyle(AnteTheme.cream.opacity(0.6))
                        MoneyPresetPicker(presets: MoneyPreset.fineCents, selectedCents: Binding(
                            get: { settings.fineCents }, set: { settings.fineCents = $0 }
                        ))
                    }
                    VStack(spacing: 10) {
                        Text("Cost per snooze")
                            .font(.footnote)
                            .foregroundStyle(AnteTheme.cream.opacity(0.6))
                        MoneyPresetPicker(presets: MoneyPreset.snoozeCostCents, selectedCents: Binding(
                            get: { settings.snoozeCostCents }, set: { settings.snoozeCostCents = $0 }
                        ))
                    }
                }
                .padding(.horizontal, 32)
            }
            .frame(maxHeight: 340)
        }
    }

    private var signInStep: some View {
        StepScaffold(
            title: "Sign in with Apple",
            subtitle: "Ante charges real money, so it needs an identity to attribute that to, and to sync your stakes and history across your own devices via iCloud.",
            primaryTitle: "Continue",
            primaryEnabled: auth.isSignedIn
        ) {
            advance()
        } content: {
            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    auth.configureRequest(request)
                } onCompletion: { result in
                    auth.handle(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .clipShape(.capsule)

                if auth.isSignedIn {
                    Label("Signed in", systemImage: "checkmark.seal.fill")
                        .font(.footnote)
                        .foregroundStyle(AnteTheme.gold)
                }
                if let authError = auth.lastError {
                    Text(authError)
                        .font(.footnote)
                        .foregroundStyle(AnteTheme.chipRed)
                        .multilineTextAlignment(.center)
                }
                #if DEBUG
                Button("Simulator: skip sign-in") { auth.devBypass() }
                    .font(.caption)
                    .foregroundStyle(AnteTheme.cream.opacity(0.4))
                #endif
            }
            .padding(.horizontal, 32)
        }
    }

    private var agreeStep: some View {
        StepScaffold(
            title: "This charges real money",
            subtitle: "Skipping the task charges \(Money.format(cents: settings.fineCents)). Each snooze charges \(Money.format(cents: settings.snoozeCostCents)). Those charges are final - see the Terms of Use.",
            primaryTitle: isStarting ? "Starting…" : "I Agree - Start the Ante",
            primaryEnabled: hasCheckedAgree && !isStarting
        ) {
            start()
        } content: {
            VStack(spacing: 16) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AnteTheme.gold)

                // Deliberately no Link/nested-interactive content inside this
                // button - mixing a tap target with embedded hyperlinks is
                // fragile for hit-testing (and for real fingers). The Terms/
                // Privacy links live in their own row below, untangled from
                // the checkbox toggle.
                Button {
                    hasCheckedAgree.toggle()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: hasCheckedAgree ? "checkmark.square.fill" : "square")
                            .font(.system(size: 22))
                            .foregroundStyle(hasCheckedAgree ? AnteTheme.gold : AnteTheme.cream.opacity(0.6))
                        Text("I have read and agree to the Terms of Use and Privacy Policy.")
                            .font(.subheadline)
                            .foregroundStyle(AnteTheme.cream)
                            .multilineTextAlignment(.leading)
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 16) {
                    Link("Terms of Use", destination: LegalLinks.terms)
                    Link("Privacy Policy", destination: LegalLinks.privacy)
                }
                .font(.footnote)
                .foregroundStyle(AnteTheme.gold)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(AnteTheme.chipRed)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private func advance() {
        if let next = OnboardingStep(rawValue: step.rawValue + 1) {
            step = next
        }
    }

    private func start() {
        isStarting = true
        errorMessage = nil
        Task {
            let authorized = await alarmEngine.requestAuthorizationIfNeeded()
            guard authorized else {
                errorMessage = "Ante needs alarm permission to wake you up. Enable it in Settings."
                isStarting = false
                return
            }
            do {
                try await alarmEngine.scheduleDailyAlarm(settings: settings)
                settings.hasAgreedToTerms = true
                settings.onboardingComplete = true
                CloudSync.shared.pushSettings(settings.snapshot)
            } catch {
                errorMessage = "Couldn't schedule the alarm: \(error.localizedDescription)"
            }
            isStarting = false
        }
    }
}

private struct StepScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    let primaryTitle: String
    var primaryEnabled: Bool = true
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 8)
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AnteTheme.cream)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AnteTheme.cream.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            content
            Spacer(minLength: 8)
            Button(action: action) {
                Text(primaryTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(primaryEnabled ? AnteTheme.gold : AnteTheme.gold.opacity(0.3))
                    .foregroundStyle(AnteTheme.feltDeep)
                    .clipShape(Capsule())
            }
            .disabled(!primaryEnabled)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }
}
