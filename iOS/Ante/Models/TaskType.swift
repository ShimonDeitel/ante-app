import Foundation

/// Each case is a real-world action the morning alarm demands proof of.
/// No reference photo is required for any of them - the verifier judges the
/// photo's content directly against `verificationQuestion`.
enum TaskType: String, Codable, CaseIterable, Identifiable {
    case makeBed
    case touchGrass
    case drinkWater

    var id: String { rawValue }

    var title: String {
        switch self {
        case .makeBed: "Make Your Bed"
        case .touchGrass: "Touch Grass"
        case .drinkWater: "Drink Water"
        }
    }

    var instruction: String {
        switch self {
        case .makeBed: "Make your bed, then show me"
        case .touchGrass: "Step outside, then show me"
        case .drinkWater: "Pour a glass of water, then show me"
        }
    }

    var systemImageName: String {
        switch self {
        case .makeBed: "bed.double.fill"
        case .touchGrass: "leaf.fill"
        case .drinkWater: "waterbottle.fill"
        }
    }

    /// Sent verbatim to the vision model as the user-turn question.
    var verificationQuestion: String {
        switch self {
        case .makeBed:
            "Does this photo show a neatly made bed - blankets pulled up, pillows arranged, no visible mess? Answer with only the single word YES or NO."
        case .touchGrass:
            "Does this photo show the person outdoors, with grass, plants, sky, pavement, or other outdoor surroundings visible - not the inside of a home? Answer with only the single word YES or NO."
        case .drinkWater:
            "Does this photo clearly show a glass, cup, or bottle of water, held or in frame? Answer with only the single word YES or NO."
        }
    }
}
