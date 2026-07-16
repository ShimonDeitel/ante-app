import SwiftUI

/// Ante is built around a stakes/poker-table language, not the black-and-
/// white minimalist default used elsewhere -- the whole product is "put
/// money on the line to wake up," so felt green + chip gold earns its
/// keep here.
enum AnteTheme {
    static let felt = Color(red: 0.043, green: 0.114, blue: 0.078)
    static let feltDeep = Color(red: 0.02, green: 0.06, blue: 0.04)
    static let gold = Color(red: 0.831, green: 0.686, blue: 0.216)
    static let goldBright = Color(red: 0.965, green: 0.827, blue: 0.404)
    static let chipRed = Color(red: 0.72, green: 0.16, blue: 0.16)
    static let cream = Color(red: 0.96, green: 0.94, blue: 0.88)

    static let feltGradient = LinearGradient(
        colors: [feltDeep, felt],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct PokerChipView: View {
    var color: Color = AnteTheme.gold
    var diameter: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
            Circle()
                .strokeBorder(AnteTheme.cream.opacity(0.85), style: StrokeStyle(lineWidth: diameter * 0.09, dash: [diameter * 0.14, diameter * 0.1]))
                .padding(diameter * 0.06)
            Circle()
                .strokeBorder(AnteTheme.cream.opacity(0.7), lineWidth: diameter * 0.03)
                .padding(diameter * 0.22)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: .black.opacity(0.4), radius: diameter * 0.08, y: diameter * 0.05)
    }
}

/// A stack whose height communicates the stake -- taller stack, bigger fine.
struct ChipStackView: View {
    var chipCount: Int
    var chipColor: Color = AnteTheme.gold

    var body: some View {
        let count = max(1, min(chipCount, 12))
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                PokerChipView(color: chipColor, diameter: 56)
                    .offset(y: -CGFloat(i) * 8)
                    .zIndex(Double(i))
            }
        }
        .frame(height: 56 + CGFloat(count) * 8)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: chipCount)
    }
}

/// A breathing glow ring, used behind the camera/verification icon.
struct PulsingGlowRing: View {
    var color: Color = AnteTheme.gold
    @State private var pulse = false

    var body: some View {
        Circle()
            .stroke(color.opacity(0.5), lineWidth: 3)
            .scaleEffect(pulse ? 1.4 : 1.0)
            .opacity(pulse ? 0 : 0.8)
            .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)
            .onAppear { pulse = true }
    }
}

/// Radial sweep shown while the on-device model is comparing the two photos.
struct ScanSweepView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.22)
            .stroke(
                AngularGradient(colors: [.clear, AnteTheme.goldBright], center: .center),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .rotationEffect(.degrees(rotation))
            .animation(.linear(duration: 1.1).repeatForever(autoreverses: false), value: rotation)
            .onAppear { rotation = 360 }
    }
}

/// A handful of chips tossed outward, used the instant a charge posts.
struct ChipBurstView: View {
    let trigger: Bool
    @State private var particles: [ChipParticle] = []

    struct ChipParticle: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let delay: Double
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                PokerChipView(color: [AnteTheme.gold, AnteTheme.chipRed, AnteTheme.cream].randomElement()!, diameter: 22)
                    .modifier(BurstOffset(angle: particle.angle, distance: particle.distance, active: trigger))
                    .opacity(trigger ? 0 : 1)
                    .animation(.easeOut(duration: 0.9).delay(particle.delay), value: trigger)
            }
        }
        .onAppear {
            particles = (0..<10).map { i in
                ChipParticle(angle: Double(i) * (360.0 / 10.0), distance: CGFloat.random(in: 70...130), delay: Double(i) * 0.02)
            }
        }
    }
}

private struct BurstOffset: ViewModifier {
    let angle: Double
    let distance: CGFloat
    let active: Bool

    func body(content: Content) -> some View {
        let radians = angle * .pi / 180
        let dx = active ? cos(radians) * distance : 0
        let dy = active ? sin(radians) * distance : 0
        content.offset(x: dx, y: dy)
    }
}
