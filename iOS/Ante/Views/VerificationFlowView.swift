import SwiftUI
import SwiftData

private enum VerificationPhase {
    case capture, analyzing, passed, failed
}

struct VerificationFlowView: View {
    @Environment(AlarmEngine.self) private var alarmEngine
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext

    @State private var phase: VerificationPhase = .capture
    @State private var showCamera = false
    @State private var showSnooze = false
    @State private var capturedImage: UIImage?
    @State private var isSettling = false
    @State private var errorMessage: String?
    @State private var burst = false

    var body: some View {
        ZStack {
            AnteTheme.feltGradient.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                switch phase {
                case .capture: captureContent
                case .analyzing: analyzingContent
                case .passed: passedContent
                case .failed: failedContent
                }

                Spacer()

                if phase == .capture {
                    Button("Snooze instead") { showSnooze = true }
                        .font(.subheadline)
                        .foregroundStyle(AnteTheme.cream.opacity(0.7))
                        .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 32)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(
                onCapture: { image in
                    capturedImage = image
                    showCamera = false
                    analyze(image)
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showSnooze) {
            SnoozeSheet()
        }
    }

    private var captureContent: some View {
        VStack(spacing: 20) {
            PulsingGlowRing()
                .frame(width: 120, height: 120)
                .overlay { Image(systemName: "bed.double.fill").font(.system(size: 40)).foregroundStyle(AnteTheme.gold) }
            Text("Make your bed, then show me")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AnteTheme.cream)
                .multilineTextAlignment(.center)
            Text("Checked on-device. The photo never leaves your phone.")
                .font(.footnote)
                .foregroundStyle(AnteTheme.cream.opacity(0.6))
                .multilineTextAlignment(.center)
            Button {
                showCamera = true
            } label: {
                Text("Open camera")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AnteTheme.gold)
                    .foregroundStyle(AnteTheme.feltDeep)
                    .clipShape(Capsule())
            }
        }
    }

    private var analyzingContent: some View {
        VStack(spacing: 20) {
            ZStack {
                ScanSweepView().frame(width: 100, height: 100)
                if let capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                }
            }
            Text("Checking against your reference photo…")
                .font(.headline)
                .foregroundStyle(AnteTheme.cream)
        }
    }

    private var passedContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(AnteTheme.gold)
            Text("Bed's made. Ante returned.")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AnteTheme.cream)
        }
    }

    private var failedContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(AnteTheme.chipRed)
            Text("Doesn't match your reference photo")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AnteTheme.cream)
                .multilineTextAlignment(.center)

            ZStack { ChipBurstView(trigger: burst) }
                .frame(height: 40)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(AnteTheme.chipRed)
            }

            Button {
                phase = .capture
            } label: {
                Text("Try again")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AnteTheme.gold)
                    .foregroundStyle(AnteTheme.feltDeep)
                    .clipShape(Capsule())
            }

            Button {
                payFine()
            } label: {
                Text(isSettling ? "Charging…" : "Can't do it, charge \(Money.format(cents: settings.fineCents))")
                    .font(.subheadline)
                    .foregroundStyle(AnteTheme.cream.opacity(0.75))
            }
            .disabled(isSettling)
        }
    }

    private func analyze(_ image: UIImage) {
        phase = .analyzing
        Task {
            guard let reference = ReferencePhotoStore.load() else {
                phase = .failed
                errorMessage = "No reference photo saved. Set one in Settings."
                return
            }
            do {
                let result = try await BedPhotoVerifier.compare(referenceImage: reference, candidateImage: image)
                if result.passed {
                    SettlementService.recordVerified(modelContext: modelContext)
                    alarmEngine.markVerifiedAndStop()
                    try? await alarmEngine.rearmDailySchedule(settings: settings)
                    phase = .passed
                } else {
                    phase = .failed
                    burst = true
                }
            } catch {
                phase = .failed
                errorMessage = "Couldn't analyze that photo. Try again."
            }
        }
    }

    private func payFine() {
        isSettling = true
        errorMessage = nil
        Task {
            do {
                _ = try await SettlementService.chargeFine(
                    cents: settings.fineCents,
                    alarmEngine: alarmEngine,
                    settings: settings,
                    modelContext: modelContext
                )
                alarmEngine.markVerifiedAndStop()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSettling = false
        }
    }
}
