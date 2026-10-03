import Foundation

/// Nutrient density per kcal relative to the user's daily needs (prototype `score()`).
enum NutrientScore {
    enum Label: Sendable {
        /// "Topkeuze": score ≥ 50 and ≤ 150 kcal per 100 g.
        case topChoice
        /// "Calorierijk": ≥ 350 kcal per 100 g.
        case energyDense

        var displayName: String {
            switch self {
            case .topChoice: "Topkeuze"
            case .energyDense: "Calorierijk"
            }
        }
    }

    /// How much of `nutrient` a food gives per kcal, relative to the daily target per kcal.
    /// 1 means the food matches the daily need per kcal. 0 for foods without kcal.
    static func ratio(_ nutrient: Nutrient, in food: Nutrients, targets: Targets) -> Double {
        guard food.kcal != 0 else { return 0 }
        return (food[nutrient] / food.kcal) / (targets[nutrient] / Double(targets.kcal))
    }

    /// Score 0–100: the ratio of each of the 12 scored nutrients, capped at 3, divided by 3, averaged.
    static func score(_ food: Nutrients, targets: Targets) -> Int {
        guard food.kcal != 0 else { return 0 }
        let sum = Nutrient.scored.reduce(0) { $0 + min(ratio($1, in: food, targets: targets), 3) / 3 }
        return Int(jsRound(sum / Double(Nutrient.scored.count) * 100))
    }

    /// Intensity 0–1 per scored nutrient for the 12-part strip, in `Nutrient.scored` order.
    static func strip(_ food: Nutrients, targets: Targets) -> [Double] {
        Nutrient.scored.map { min(ratio($0, in: food, targets: targets), 3) / 3 }
    }

    /// Whether a nutrient is highlighted in the food detail (ratio ≥ 1.5, never carbs or fat).
    static func isHighlighted(_ nutrient: Nutrient, in food: Nutrients, targets: Targets) -> Bool {
        nutrient != .carbs && nutrient != .fat && ratio(nutrient, in: food, targets: targets) >= 1.5
    }

    static func labels(score: Int, kcalPer100g kcal: Double) -> [Label] {
        var labels: [Label] = []
        if score >= 50 && kcal <= 150 { labels.append(.topChoice) }
        if kcal >= 350 { labels.append(.energyDense) }
        return labels
    }
}
