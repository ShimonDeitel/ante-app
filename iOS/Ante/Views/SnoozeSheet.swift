import SwiftUI

struct SnoozeSheet: View {
    @Environment(AlarmEngine.self) private var alarmEngine
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var isCharging = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AnteTheme.feltGradient.ignoresSafeArea()
            VStack(spacing: 24) {
                PokerChipView(diameter: 72)
                Text("Snooze \(settings.snoozeMinutes) minutes")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AnteTheme.cream)
                Text(settings.snoozeCostCents == 0
                     ? "Free, for now. Set a snooze cost in Settings if you want it to sting."
                     : "This charges \(Money.format(cents: settings.snoozeCostCents)). The bed check still has to happen when it rings again.")
                    .font(.subheadline)
                    .foregroundStyle(AnteTheme.cream.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(AnteTheme.chipRed)
                }

                Button {
                    snooze()
                } label: {
                    Text(isCharging ? "Charging…" : (settings.snoozeCostCents == 0 ? "Snooze" : "Pay & snooze"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AnteTheme.gold)
                        .foregroundStyle(AnteTheme.feltDeep)
                        .clipShape(Capsule())
                }
                .disabled(isCharging)
                .padding(.horizontal, 32)

                Button("Never mind") { dismiss() }
                    .foregroundStyle(AnteTheme.cream.opacity(0.6))
            }
        }
    }

    private func snooze() {
        isCharging = true
        errorMessage = nil
        Task {
            do {
                _ = try await SettlementService.chargeSnooze(
                    cents: settings.snoozeCostCents,
                    alarmEngine: alarmEngine,
                    settings: settings
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCharging = false
        }
    }
}
