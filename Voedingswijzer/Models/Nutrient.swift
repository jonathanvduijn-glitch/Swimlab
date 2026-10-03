import Foundation

/// A nutrient tracked by the app. Raw values match the keys used in the prototype and the seed JSON.
enum Nutrient: String, CaseIterable, Codable, Sendable {
    case kcal
    case protein = "p"
    case carbs = "c"
    case fat = "f"
    case fiber = "fib"
    case vitaminC = "vc"
    case vitaminA = "va"
    case vitaminD = "vd"
    case vitaminB12 = "b12"
    case folate = "fol"
    case iron = "fe"
    case calcium = "ca"
    case magnesium = "mg"
    case potassium = "k"
    case zinc = "zn"

    /// The ten vitamins and minerals shown on the Today screen.
    static let micros: [Nutrient] = [
        .vitaminC, .vitaminA, .vitaminD, .vitaminB12, .folate,
        .iron, .calcium, .magnesium, .potassium, .zinc,
    ]

    /// The twelve nutrients that make up the nutrient density score.
    static let scored: [Nutrient] = [.protein, .fiber] + micros

    /// Dutch display name.
    var displayName: String {
        switch self {
        case .kcal: "Energie"
        case .protein: "Eiwit"
        case .carbs: "Koolhydraten"
        case .fat: "Vet"
        case .fiber: "Vezels"
        case .vitaminC: "Vitamine C"
        case .vitaminA: "Vitamine A"
        case .vitaminD: "Vitamine D"
        case .vitaminB12: "Vitamine B12"
        case .folate: "Foliumzuur"
        case .iron: "IJzer"
        case .calcium: "Calcium"
        case .magnesium: "Magnesium"
        case .potassium: "Kalium"
        case .zinc: "Zink"
        }
    }

    var unit: String {
        switch self {
        case .kcal: "kcal"
        case .protein, .carbs, .fat, .fiber: "g"
        case .vitaminC, .iron, .calcium, .magnesium, .potassium, .zinc: "mg"
        case .vitaminA, .vitaminD, .vitaminB12, .folate: "µg"
        }
    }
}

/// A set of nutrient amounts, e.g. per 100 g of a food or the total for a day.
/// Missing nutrients read as 0. Encodes as a flat JSON object keyed by `Nutrient.rawValue`.
struct Nutrients: Hashable, Sendable {
    private var values: [Nutrient: Double]

    init(_ values: [Nutrient: Double] = [:]) {
        self.values = values
    }

    static let zero = Nutrients()

    subscript(nutrient: Nutrient) -> Double {
        get { values[nutrient] ?? 0 }
        set { values[nutrient] = newValue }
    }

    var kcal: Double { self[.kcal] }

    /// The amounts in `grams` of a food whose values are given per 100 g.
    func scaled(toGrams grams: Double) -> Nutrients {
        var result = Nutrients()
        for (nutrient, value) in values {
            result[nutrient] = value * grams / 100
        }
        return result
    }

    /// Every amount multiplied by `factor`.
    func multiplied(by factor: Double) -> Nutrients {
        Nutrients(values.mapValues { $0 * factor })
    }

    static func + (lhs: Nutrients, rhs: Nutrients) -> Nutrients {
        var result = lhs
        result += rhs
        return result
    }

    static func += (lhs: inout Nutrients, rhs: Nutrients) {
        for (nutrient, value) in rhs.values {
            lhs[nutrient] += value
        }
    }
}

extension Nutrients: Codable {
    private struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        var values: [Nutrient: Double] = [:]
        for key in container.allKeys {
            guard let nutrient = Nutrient(rawValue: key.stringValue) else {
                throw DecodingError.dataCorruptedError(
                    forKey: key, in: container, debugDescription: "Unknown nutrient \(key.stringValue)")
            }
            values[nutrient] = try container.decode(Double.self, forKey: key)
        }
        self.init(values)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        for nutrient in Nutrient.allCases where values[nutrient] != nil {
            try container.encode(self[nutrient], forKey: Key(stringValue: nutrient.rawValue))
        }
    }
}
