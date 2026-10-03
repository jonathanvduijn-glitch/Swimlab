import Testing
@testable import Voedingswijzer

@Suite("Nutrient score")
struct NutrientScoreTests {
    let targets = Fixtures.referenceTargets

    @Test(arguments: [
        ("Spinazie", 80), ("Broccoli", 77), ("Olijfolie", 0), ("Magere kwark", 43),
        ("Kipfilet (gebakken)", 27), ("Havermout", 32), ("Pure chocolade 85%", 28), ("Banaan", 38),
    ])
    func scoresMatchPrototype(name: String, score: Int) {
        #expect(NutrientScore.score(Fixtures.food(name).per100g, targets: targets) == score)
    }

    @Test func foodWithoutKcalScoresZero() {
        #expect(NutrientScore.score(Nutrients([.protein: 10]), targets: targets) == 0)
        #expect(NutrientScore.ratio(.protein, in: Nutrients([.protein: 10]), targets: targets) == 0)
    }

    @Test func ratioIsCappedAtThree() {
        // Pure protein: 4 kcal per g → ratio far above 3, contributes exactly 1/12.
        let protein = Nutrients([.kcal: 400, .protein: 100])
        #expect(NutrientScore.score(protein, targets: targets) == Int(jsRound(100.0 / 12)))
    }

    @Test func stripHasTwelveParts() {
        let strip = NutrientScore.strip(Fixtures.food("Spinazie").per100g, targets: targets)
        #expect(strip.count == 12)
        #expect(strip.allSatisfy { (0...1).contains($0) })
        #expect(NutrientScore.strip(Fixtures.food("Olijfolie").per100g, targets: targets).allSatisfy { $0 < 0.2 })
    }

    @Test func labels() {
        #expect(NutrientScore.labels(score: 80, kcalPer100g: 23) == [.topChoice])
        #expect(NutrientScore.labels(score: 50, kcalPer100g: 150) == [.topChoice])
        #expect(NutrientScore.labels(score: 49, kcalPer100g: 100) == [])
        #expect(NutrientScore.labels(score: 60, kcalPer100g: 151) == [])
        #expect(NutrientScore.labels(score: 0, kcalPer100g: 884) == [.energyDense])
        #expect(NutrientScore.labels(score: 10, kcalPer100g: 350) == [.energyDense])
        #expect(NutrientScore.labels(score: 10, kcalPer100g: 349) == [])
    }

    @Test func highlightSkipsCarbsAndFat() {
        let oil = Fixtures.food("Olijfolie").per100g
        #expect(!NutrientScore.isHighlighted(.fat, in: oil, targets: targets))
        let spinach = Fixtures.food("Spinazie").per100g
        #expect(NutrientScore.isHighlighted(.vitaminA, in: spinach, targets: targets))
    }
}
