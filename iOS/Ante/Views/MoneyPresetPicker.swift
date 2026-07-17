import SwiftUI

/// A wrap of tappable preset amounts. Replaces the old continuous slider -
/// fixed stakes only, decided fast instead of dragged into place.
struct MoneyPresetPicker: View {
    let presets: [Int]
    @Binding var selectedCents: Int

    private let columns = [GridItem(.adaptive(minimum: 74), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(presets, id: \.self) { cents in
                let isOn = cents == selectedCents
                Button {
                    selectedCents = cents
                } label: {
                    Text(cents == 0 ? "Free" : Money.format(cents: cents))
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isOn ? AnteTheme.gold : AnteTheme.felt)
                        .foregroundStyle(isOn ? AnteTheme.feltDeep : AnteTheme.cream)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AnteTheme.gold.opacity(isOn ? 0 : 0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
