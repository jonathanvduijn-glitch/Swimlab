import Testing
@testable import Voedingswijzer

@Suite("Targets")
struct TargetsTests {
    @Test func referenceProfile() {
        // Man, 35, 184 cm, 99.3 kg, 15.5 % fat, measured BMR 2182, activity 1.55, 2.0 g/kg, own target 2600.
        let t = Targets(profile: .reference)
        #expect(t.kcal == 2600)
        #expect(t.protein == 199)
        #expect(t.fat == 78)
        #expect(t.carbs == 276)
        #expect(t.bmr == 2182)
        #expect(t.tdee == 3382)
        #expect(t.fiber == 40)
        #expect(t[.vitaminC] == 75)
        #expect(t[.vitaminA] == 800)
        #expect(t[.vitaminD] == 10)
        #expect(t[.vitaminB12] == 4)
        #expect(t[.folate] == 300)
        #expect(t[.iron] == 11)
        #expect(t[.calcium] == 1000)
        #expect(t[.magnesium] == 350)
        #expect(t[.potassium] == 3500)
        #expect(t[.zinc] == 11)
    }

    @Test func goalFactorWhenNoOwnTarget() {
        var p = BodyProfile.reference
        p.customKcalTarget = 0
        let t = Targets(profile: p)
        // 2182 × 1.55 × 0.85 = 2874.8 → rounded to 10.
        #expect(t.kcal == 2870)
        #expect(t.fat == 86)
        #expect(t.carbs == 325)
    }

    @Test func katchMcArdleWhenBodyFatKnown() {
        var p = BodyProfile.reference
        p.measuredBMR = 0
        let t = Targets(profile: p)
        // 370 + 21.6 × 99.3 × 0.845
        #expect(t.bmr == 2182)
        #expect(t.tdee == 3383)
    }

    @Test func mifflinForMen() {
        var p = BodyProfile.reference
        p.measuredBMR = 0
        p.bodyFatPercent = 0
        let t = Targets(profile: p)
        #expect(t.bmr == 1973)
        #expect(t.tdee == 3058)
    }

    @Test func mifflinForWomenOver50() {
        let p = BodyProfile(
            sex: .female, age: 55, heightCm: 168, weightKg: 70, bodyFatPercent: 0, measuredBMR: 0,
            activity: ActivityLevel.light.rawValue, goal: Goal.loseWeightSlowly.rawValue, proteinPerKg: 1.6,
            customKcalTarget: 0)
        let t = Targets(profile: p)
        #expect(t.bmr == 1314)
        #expect(t.tdee == 1807)
        #expect(t.kcal == 1630)
        #expect(t.protein == 112)
        #expect(t.carbs == 185)
        #expect(t.fat == 49)
        #expect(t.fiber == 32)
        #expect(t[.vitaminA] == 680)
        #expect(t[.iron] == 11)
        #expect(t[.calcium] == 1100)
        #expect(t[.magnesium] == 300)
        #expect(t[.zinc] == 8)
    }

    @Test func microsByAge() {
        var woman = BodyProfile.reference
        woman.sex = .female
        woman.age = 30
        #expect(Targets(profile: woman)[.iron] == 16)
        #expect(Targets(profile: woman)[.calcium] == 1000)
        woman.age = 72
        #expect(Targets(profile: woman)[.vitaminD] == 20)
        #expect(Targets(profile: woman)[.iron] == 11)
        #expect(Targets(profile: woman)[.calcium] == 1100)
    }

    @Test func carbsNeverNegative() {
        var p = BodyProfile.reference
        p.customKcalTarget = 800
        p.proteinPerKg = 2.2
        #expect(Targets(profile: p).carbs == 0)
    }

    @Test func deficitReferenceText() {
        let d = Targets(profile: .reference).deficit
        #expect(d.kcalPerDay == 782)
        #expect(isClose(d.kgPerWeek, 782.0 * 7 / 7700))
        #expect(d.pace == .good)
        #expect(d.message == "Met 2.600 kcal eet je ongeveer 782 kcal per dag onder je geschatte verbruik. "
            + "Dat is zo'n 0,7 kg per week. Een goed tempo om vet te verliezen en spier te behouden of op te bouwen.")
    }

    @Test(arguments: [
        (2000.0, DeficitSummary.Pace.fast),
        (3100.0, DeficitSummary.Pace.gentle),
        (3382.0, DeficitSummary.Pace.noDeficit),
        (3500.0, DeficitSummary.Pace.noDeficit),
    ])
    func deficitPace(target: Double, pace: DeficitSummary.Pace) {
        var p = BodyProfile.reference
        p.customKcalTarget = target
        #expect(Targets(profile: p).deficit.pace == pace)
    }

    @Test func deficitTexts() {
        var p = BodyProfile.reference
        p.customKcalTarget = 2000
        #expect(Targets(profile: p).deficit.message.hasSuffix(
            "Dat is zo'n 1,3 kg per week. Dat is snel: grote kans dat je spiermassa en kracht verliest."))
        p.customKcalTarget = 3100
        #expect(Targets(profile: p).deficit.message.hasSuffix(
            "Dat is zo'n 0,3 kg per week. Rustig tempo, ideaal voor recompositie."))
        p.customKcalTarget = 3500
        #expect(Targets(profile: p).deficit.message == "Je eet op of boven je geschatte verbruik van 3.382 kcal.")
    }
}
