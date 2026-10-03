import Foundation

/// A supplement as the user sees it: a default or custom supplement with their on/off and dose applied.
struct ResolvedSupplement: Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let dose: Double
    let unit: String
    let nutrient: Nutrient?
    let perUnit: Nutrients?
    let isOn: Bool
    let isCustom: Bool

    /// What taking this supplement adds to the day's totals.
    var contribution: Nutrients {
        var result = Nutrients()
        if let nutrient { result[nutrient] += dose }
        if let perUnit { result += perUnit.multiplied(by: dose) }
        return result
    }
}

/// The user's override for a supplement (Profile → Mijn supplementen).
struct SupplementSetting: Hashable, Codable, Sendable {
    var isOn: Bool?
    var dose: Double?

    init(isOn: Bool? = nil, dose: Double? = nil) {
        self.isOn = isOn
        self.dose = dose
    }
}

/// A supplement the user added themselves.
struct CustomSupplement: Hashable, Codable, Sendable, Identifiable {
    let id: String
    var name: String
    var dose: Double
    var unit: String
    var nutrient: Nutrient?
}

enum Supplements {
    static let creatineID = "creatine"

    /// Units offered when adding a custom supplement.
    static let units = ["g", "mg", "µg", "capsule", "tablet", "ml"]

    /// Defaults followed by custom supplements, with the user's settings applied (prototype `suppList()`).
    static func resolve(
        defaults: [Supplement], custom: [CustomSupplement], settings: [String: SupplementSetting]
    ) -> [ResolvedSupplement] {
        let base = defaults.map {
            ResolvedSupplement(
                id: $0.id, name: $0.name, dose: $0.dose, unit: $0.unit, nutrient: $0.nutrient,
                perUnit: $0.perUnit, isOn: $0.defaultOn, isCustom: false)
        } + custom.map {
            ResolvedSupplement(
                id: $0.id, name: $0.name, dose: $0.dose, unit: $0.unit, nutrient: $0.nutrient,
                perUnit: nil, isOn: true, isCustom: true)
        }
        return base.map { s in
            let setting = settings[s.id]
            return ResolvedSupplement(
                id: s.id, name: s.name, dose: setting?.dose ?? s.dose, unit: s.unit, nutrient: s.nutrient,
                perUnit: s.perUnit, isOn: setting?.isOn ?? s.isOn, isCustom: s.isCustom)
        }
    }

    static func active(_ supplements: [ResolvedSupplement]) -> [ResolvedSupplement] {
        supplements.filter(\.isOn)
    }

    /// Nutrients added by the supplements taken on a day. Like the prototype, this counts every
    /// supplement that was ticked, also one that has since been switched off.
    static func contribution(of supplements: [ResolvedSupplement], taken: Set<String>) -> Nutrients {
        supplements.filter { taken.contains($0.id) }.reduce(Nutrients()) { $0 + $1.contribution }
    }

    /// Consecutive days `isTaken` holds, counting back from `day`, or from the day before
    /// when `day` itself is not ticked yet (prototype `streak()`).
    static func streak(from day: DayKey, isTaken: (DayKey) -> Bool) -> Int {
        var current = isTaken(day) ? day : day.shifted(by: -1)
        var count = 0
        while isTaken(current) {
            count += 1
            current = current.shifted(by: -1)
        }
        return count
    }

    static func streak(from day: DayKey, takenDays: Set<DayKey>) -> Int {
        streak(from: day) { takenDays.contains($0) }
    }

    /// The seven days ending on `day`, oldest first, with whether each was ticked.
    static func lastSevenDays(endingOn day: DayKey, takenDays: Set<DayKey>) -> [(day: DayKey, taken: Bool)] {
        (0...6).reversed().map { offset -> (day: DayKey, taken: Bool) in
            let key = day.shifted(by: -offset)
            return (key, takenDays.contains(key))
        }
    }

    /// Validates a new custom supplement; returns the prototype's Dutch message on failure.
    static func validateCustom(name: String, unit: String, nutrient: Nutrient?) -> String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Geef het supplement een naam"
        }
        if let nutrient, unit != nutrient.unit {
            return "Kies \(nutrient.unit) als eenheid voor \(nutrient.displayName.lowercased())"
        }
        return nil
    }
}
