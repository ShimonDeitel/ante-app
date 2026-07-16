import SwiftUI

private enum OnboardingStep: Int, CaseIterable {
    case welcome, referencePhoto, schedule, stakes, agree
}

struct OnboardingView: View {
    @Environment(AlarmEngine.self) private var alarmEngine
    @Environment(AppSettings.self) private var settings

    @State private var step: OnboardingStep = .welcome
    @State private var showCamera = false
    @State private var referenceImage: UIImage?
    @State private var isStarting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            stepDots
                .padding(.top, 24)

            Group {
                switch step {
                case .welcome: welcomeStep
                case .referencePhoto: referencePhotoStep
                case .schedule: scheduleStep
                case .stakes: stakesStep
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
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(
                onCapture: { image in
                    referenceImage = image
                    ReferencePhotoStore.save(image)
                    showCamera = false
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
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
            subtitle: "You put money on the line to wake up. Make your bed and the ante's returned. Skip it, and it's forfeit.",
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

    private var referencePhotoStep: some View {
        StepScaffold(
            title: "Show me a made bed",
            subtitle: "Take one reference photo now. Every morning, Ante compares your wake-up photo against this one, entirely on your device.",
            primaryTitle: referenceImage == nil ? "Open camera" : "Use this photo",
            primaryEnabled: true
        ) {
            if referenceImage == nil {
                showCamera = true
            } else {
                advance()
            }
        } content: {
            if let referenceImage {
                Image(uiImage: referenceImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(AnteTheme.gold, lineWidth: 2))
                Button("Retake") { showCamera = true }
                    .foregroundStyle(AnteTheme.gold)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(AnteTheme.felt)
                    .frame(width: 220, height: 220)
                    .overlay(Image(systemName: "camera.fill").font(.system(size: 36)).foregroundStyle(AnteTheme.gold.opacity(0.7)))
            }
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
            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text(Money.format(cents: settings.fineCents))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(AnteTheme.goldBright)
                    Slider(value: Binding(get: { settings.fineDollars }, set: { settings.fineDollars = $0 }), in: 1...1000, step: 1)
                        .tint(AnteTheme.gold)
                    Text("Fine for skipping the bed check")
                        .font(.footnote)
                        .foregroundStyle(AnteTheme.cream.opacity(0.6))
                }
                VStack(spacing: 10) {
                    Text(Money.format(cents: settings.snoozeCostCents))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(AnteTheme.gold)
                    Stepper(
                        "Cost per snooze",
                        value: Binding(get: { settings.snoozeCostDollars }, set: { settings.snoozeCostDollars = $0 }),
                        in: 0...50, step: 1
                    )
                    .foregroundStyle(AnteTheme.cream)
                }
                .padding(.horizontal, 12)
            }
            .padding(.horizontal, 32)
        }
    }

    private var agreeStep: some View {
        StepScaffold(
            title: "This charges real money",
            subtitle: "Skipping the bed check charges \(Money.format(cents: settings.fineCents)). Each snooze charges \(Money.format(cents: settings.snoozeCostCents)). You can change both any time in Settings.",
            primaryTitle: isStarting ? "Starting…" : "Start the ante",
            primaryEnabled: !isStarting
        ) {
            start()
        } content: {
            VStack(spacing: 16) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AnteTheme.gold)
                Text("By continuing you agree to Ante's Terms of Use and Privacy Policy.")
                    .font(.footnote)
                    .foregroundStyle(AnteTheme.cream.opacity(0.6))
                    .multilineTextAlignment(.center)
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
                settings.onboardingComplete = true
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
