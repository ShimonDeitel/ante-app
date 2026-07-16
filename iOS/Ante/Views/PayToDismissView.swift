import SwiftUI
import SwiftData

struct PayToDismissView: View {
    let settlement: SharedStore.PendingSettlement
    var onResolved: () -> Void

    @Environment(AlarmEngine.self) private var alarmEngine
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext

    @State private var isPaying = false
    @State private var receipt: Receipt?
    @State private var errorMessage: String?
    @State private var burst = false

    var body: some View {
        ZStack {
            AnteTheme.feltGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                if let receipt {
                    receiptView(receipt)
                } else {
                    owedView
                }

                Spacer()

                if receipt == nil {
                    Button {
                        pay()
                    } label: {
                        Text(isPaying ? "Charging…" : "Pay \(Money.format(cents: settlement.amountCents))")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AnteTheme.gold)
                            .foregroundStyle(AnteTheme.feltDeep)
                            .clipShape(Capsule())
                    }
                    .disabled(isPaying)
                } else {
                    Button {
                        onResolved()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AnteTheme.gold)
                            .foregroundStyle(AnteTheme.feltDeep)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }

    private var owedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AnteTheme.chipRed)
            Text("You stopped the alarm without checking in")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AnteTheme.cream)
                .multilineTextAlignment(.center)
            Text("The ante was \(Money.format(cents: settlement.amountCents)). It's owed now. You set it before this morning, not after.")
                .font(.subheadline)
                .foregroundStyle(AnteTheme.cream.opacity(0.65))
                .multilineTextAlignment(.center)
            ZStack { ChipBurstView(trigger: burst) }.frame(height: 30)
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(AnteTheme.chipRed)
            }
        }
    }

    private func receiptView(_ receipt: Receipt) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(AnteTheme.gold)
            Text("Settled")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AnteTheme.cream)
            VStack(spacing: 6) {
                Text(Money.format(cents: receipt.amountCents))
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundStyle(AnteTheme.goldBright)
                Text(receipt.reason)
                    .font(.footnote)
                    .foregroundStyle(AnteTheme.cream.opacity(0.6))
                if receipt.isSandbox {
                    Text("SANDBOX CHARGE. No real card on file yet")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(AnteTheme.chipRed)
                }
            }
            .padding(20)
            .background(AnteTheme.felt, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(AnteTheme.gold.opacity(0.4), lineWidth: 1))
        }
    }

    private func pay() {
        isPaying = true
        errorMessage = nil
        burst = true
        Task {
            do {
                let result = try await SettlementService.chargeFine(
                    cents: settlement.amountCents,
                    alarmEngine: alarmEngine,
                    settings: settings,
                    modelContext: modelContext
                )
                receipt = result
            } catch {
                errorMessage = error.localizedDescription
            }
            isPaying = false
        }
    }
}
