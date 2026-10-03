import Foundation

enum Sex: String, CaseIterable, Codable, Sendable {
    case male = "man"
    case female = "vrouw"
}

/// Activity multiplier on top of BMR.
enum ActivityLevel: Double, CaseIterable, Codable, Sendable {
    case sedentary = 1.2
    case light = 1.375
    case moderate = 1.55
    case veryActive = 1.725
    case extreme = 1.9

    var displayName: String {
        switch self {
        case .sedentary: "Zittend"
        case .light: "Licht actief"
        case .moderate: "Gemiddeld"
        case .veryActive: "Zeer actief"
        case .extreme: "Extreem"
        }
    }
}

/// Goal, expressed as a factor on TDEE.
enum Goal: Double, CaseIterable, Codable, Sendable {
    case recomposition = 0.85
    case loseWeight = 0.8
    case loseWeightSlowly = 0.9
    case maintain = 1.0
    case buildMuscle = 1.1

    var displayName: String {
        switch self {
        case .recomposition: "Recompositie (spier op, vet af)"
        case .loseWeight: "Afvallen"
        case .loseWeightSlowly: "Rustig afvallen"
        case .maintain: "Op gewicht blijven"
        case .buildMuscle: "Spiermassa opbouwen"
        }
    }
}

/// The profile values the targets are calculated from.
struct BodyProfile: Hashable, Sendable {
    var sex: Sex
    var age: Double
    var heightCm: Double
    var weightKg: Double
    /// Body fat percentage; 0 = unknown.
    var bodyFatPercent: Double
    /// Measured BMR in kcal; 0 = calculate.
    var measuredBMR: Double
    var activity: Double
    var goal: Double
    /// Protein in g per kg body weight.
    var proteinPerKg: Double
    /// Own kcal target; 0 = derive from goal.
    var customKcalTarget: Double

    /// The prototype's default profile.
    static let reference = BodyProfile(
        sex: .male, age: 35, heightCm: 184, weightKg: 99.3, bodyFatPercent: 15.5, measuredBMR: 2182,
        activity: ActivityLevel.moderate.rawValue, goal: Goal.recomposition.rawValue,
        proteinPerKg: 2.0, customKcalTarget: 2600)
}

/// Daily targets, as calculated by the prototype's `targets()`.
struct Targets: Hashable, Sendable {
    let kcal: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let bmr: Int
    let tdee: Int
    /// Fiber and micronutrient targets (g, mg or µg, see `Nutrient.unit`).
    let fiber: Double
    let micros: [Nutrient: Double]

    init(profile p: BodyProfile) {
        let leanMass: Double? = p.bodyFatPercent > 0 ? p.weightKg * (1 - p.bodyFatPercent / 100) : nil
        let bmr: Double
        if p.measuredBMR > 0 {
            bmr = p.measuredBMR
        } else if let leanMass, leanMass != 0 {
            // Katch-McArdle
            bmr = 370 + 21.6 * leanMass
        } else {
            // Mifflin-St Jeor
            bmr = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age + (p.sex == .male ? 5 : -161)
        }
        let tdee = bmr * p.activity
        let kcal = p.customKcalTarget > 0 ? jsRound(p.customKcalTarget) : jsRound(tdee * p.goal / 10) * 10
        let protein = jsRound(p.proteinPerKg * p.weightKg)
        let fat = jsRound(kcal * 0.27 / 9)
        let carbs = max(0, jsRound((kcal - protein * 4 - fat * 9) / 4))

        self.kcal = Int(kcal)
        self.protein = Int(protein)
        self.fat = Int(fat)
        self.carbs = Int(carbs)
        self.bmr = Int(jsRound(bmr))
        self.tdee = Int(jsRound(tdee))

        let male = p.sex == .male
        self.fiber = male ? 40 : 32
        self.micros = [
            .vitaminC: 75,
            .vitaminA: male ? 800 : 680,
            .vitaminD: p.age >= 70 ? 20 : 10,
            .vitaminB12: 4.0,
            .folate: 300,
            .iron: male ? 11 : (p.age >= 50 ? 11 : 16),
            .calcium: p.age >= 51 && !male ? 1100 : 1000,
            .magnesium: male ? 350 : 300,
            .potassium: 3500,
            .zinc: male ? 11 : 8,
        ]
    }

    /// The daily target for any nutrient.
    subscript(nutrient: Nutrient) -> Double {
        switch nutrient {
        case .kcal: Double(kcal)
        case .protein: Double(protein)
        case .carbs: Double(carbs)
        case .fat: Double(fat)
        case .fiber: fiber
        default: micros[nutrient] ?? 0
        }
    }

    var deficit: DeficitSummary { DeficitSummary(targets: self) }
}

/// Deficit versus TDEE and the expected pace, shown in Profile.
struct DeficitSummary: Hashable, Sendable {
    enum Pace: Sendable {
        /// Eating at or above TDEE.
        case noDeficit
        /// Under 0.4 kg per week.
        case gentle
        /// 0.4 to 1 kg per week.
        case good
        /// Over 1 kg per week.
        case fast
    }

    let kcalPerDay: Int
    let kgPerWeek: Double
    let pace: Pace
    private let targetKcal: Int
    private let tdee: Int

    init(targets: Targets) {
        let deficit = targets.tdee - targets.kcal
        let kg = Double(deficit) * 7 / 7700
        kcalPerDay = deficit
        kgPerWeek = kg
        targetKcal = targets.kcal
        tdee = targets.tdee
        if deficit <= 0 {
            pace = .noDeficit
        } else if kg > 1 {
            pace = .fast
        } else if kg >= 0.4 {
            pace = .good
        } else {
            pace = .gentle
        }
    }

    /// The note shown in Profile, word for word as in the prototype.
    var message: String {
        guard pace != .noDeficit else {
            return "Je eet op of boven je geschatte verbruik van \(DutchNumber.format(Double(tdee))) kcal."
        }
        let advice = switch pace {
        case .fast: "Dat is snel: grote kans dat je spiermassa en kracht verliest."
        case .good: "Een goed tempo om vet te verliezen en spier te behouden of op te bouwen."
        case .gentle, .noDeficit: "Rustig tempo, ideaal voor recompositie."
        }
        return "Met \(DutchNumber.format(Double(targetKcal))) kcal eet je ongeveer "
            + "\(DutchNumber.format(Double(kcalPerDay))) kcal per dag onder je geschatte verbruik. "
            + "Dat is zo'n \(DutchNumber.format(kgPerWeek, digits: 1)) kg per week. \(advice)"
    }
}
