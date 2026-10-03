import Testing
@testable import Voedingswijzer

@Suite("Plan engine")
struct PlanEngineTests {
    // MARK: Options

    @Test func optionIndices() {
        // pool[(w*3 + i + floor(w*3/n)) % n]
        #expect(PlanEngine.optionIndices(weekday: 0, poolSize: 9) == [0, 1, 2])
        #expect(PlanEngine.optionIndices(weekday: 3, poolSize: 9) == [1, 2, 3])
        #expect(PlanEngine.optionIndices(weekday: 2, poolSize: 6) == [1, 2, 3])
        #expect(PlanEngine.optionIndices(weekday: 6, poolSize: 6) == [3, 4, 5])
        #expect(PlanEngine.optionIndices(weekday: 6, poolSize: 14) == [5, 6, 7])
    }

    @Test(arguments: 0..<7)
    func budgetOptionsMatchPrototype(weekday: Int) {
        let engine = Fixtures.engine()
        for slot in MealSlot.allCases {
            #expect(engine.options(slot, weekday: weekday).map(\.name) == PrototypeReference.budgetOptions[weekday][slot])
        }
    }

    @Test func choicesAreStoredPerWeekdayAndSlot() {
        var choices = PlanChoices()
        choices.choose(2, weekday: 0, slot: .dinner)
        #expect(choices.choice(weekday: 0, slot: .dinner) == 2)
        #expect(choices.choice(weekday: 1, slot: .dinner) == 0)
        #expect(choices.choice(weekday: 0, slot: .lunch) == 0)
        let engine = Fixtures.engine(choices: choices)
        #expect(engine.chosenMeal(.dinner, weekday: 0)?.name == "Spaghetti bolognese")
        #expect(engine.chosenMeal(.dinner, weekday: 1)?.name == "Aardappels, kipdij en sperziebonen")
    }

    @Test func invalidChoiceFallsBackToFirstOption() {
        var choices = PlanChoices()
        choices.choose(7, weekday: 0, slot: .lunch)
        #expect(choices.choice(weekday: 0, slot: .lunch) == 0)
    }

    // MARK: Day factor

    @Test(arguments: 0..<7)
    func dayFactorsMatchPrototype(weekday: Int) {
        #expect(isClose(Fixtures.engine(.budget).dayFactor(weekday: weekday), PrototypeReference.budgetDayFactors[weekday]))
        #expect(isClose(Fixtures.engine(.varied).dayFactor(weekday: weekday), PrototypeReference.variedDayFactors[weekday]))
    }

    @Test func dayFactorBounds() {
        #expect(PlanEngine.dayFactor(targetKcal: 2600, rawKcal: 2600) == 1)
        #expect(PlanEngine.dayFactor(targetKcal: 2600, rawKcal: 1000) == 1.4)
        #expect(PlanEngine.dayFactor(targetKcal: 2600, rawKcal: 5000) == 0.7)
        #expect(isClose(PlanEngine.dayFactor(targetKcal: 2600, rawKcal: 2600 / 1.4), 1.4))
        #expect(isClose(PlanEngine.dayFactor(targetKcal: 2600, rawKcal: 2600 / 0.7), 0.7))
        #expect(isClose(PlanEngine.dayFactor(targetKcal: 2600, rawKcal: 2000), 1.3))
        #expect(PlanEngine.dayFactor(targetKcal: 2600, rawKcal: 0) == 1.4)
        #expect(PlanEngine.dayFactor(targetKcal: 2600, rawKcal: 1000, autoScale: false) == 1)
    }

    @Test func liveFactorBounds() {
        #expect(PlanEngine.liveFactor(leftKcal: 100, rawOpenKcal: 1000) == 0.4)
        #expect(PlanEngine.liveFactor(leftKcal: -500, rawOpenKcal: 1000) == 0.4)
        #expect(PlanEngine.liveFactor(leftKcal: 3000, rawOpenKcal: 1000) == 1.6)
        #expect(isClose(PlanEngine.liveFactor(leftKcal: 1200, rawOpenKcal: 1000), 1.2))
        #expect(PlanEngine.liveFactor(leftKcal: 1000, rawOpenKcal: 0) == 1)
        #expect(PlanEngine.liveFactor(leftKcal: 100, rawOpenKcal: 1000, autoScale: false) == 1)
    }

    @Test func autoScaleOffKeepsRecipeAmounts() {
        let plan = Fixtures.engine(autoScale: false).dayPlan(weekday: 0)
        #expect(plan.factor == 1)
        let breakfast = plan.meals.first { $0.slot == .breakfast }
        #expect(breakfast?.items.map(\.grams) == [105, 150, 50, 5, 100])
    }

    // MARK: Portions

    @Test(arguments: [
        (105.0, 1.4, 145.0), (150, 0.7, 105), (2, 1, 5), (3, 1, 5), (12.5, 1, 15),
        (7.5, 1, 10), (250, 1.13, 285), (10, 0.4, 5), (102.5, 1, 105),
    ])
    func portionRounding(grams: Double, factor: Double, expected: Double) {
        #expect(PlanEngine.portion(grams: grams, factor: factor) == expected)
    }

    @Test(arguments: 0..<7)
    func budgetPortionsMatchPrototype(weekday: Int) {
        let plan = Fixtures.engine().dayPlan(weekday: weekday)
        #expect(!plan.isLive)
        for meal in plan.meals {
            let expected = PrototypeReference.budgetMeals[weekday][meal.slot] ?? []
            #expect(meal.items.map(\.name) == expected.map { $0.name })
            #expect(meal.items.map(\.grams) == expected.map { $0.grams })
        }
    }

    // MARK: Live day

    private func breakfastLog() -> [LoggedFood] {
        let engine = Fixtures.engine()
        return engine.items(.breakfast, weekday: 0, factor: engine.dayFactor(weekday: 0)).map {
            LoggedFood(name: $0.name, grams: $0.grams, per100g: $0.per100g, slot: .breakfast)
        }
    }

    private func oil(_ grams: Double) -> [LoggedFood] {
        [LoggedFood(food: Fixtures.food("Olijfolie"), grams: grams)]
    }

    @Test func liveOnlyOnTheLogDay() {
        let engine = Fixtures.engine()
        #expect(engine.dayPlan(weekday: 0, logDay: Fixtures.monday, logged: [], markedEaten: []).isLive)
        #expect(!engine.dayPlan(weekday: 1, logDay: Fixtures.monday, logged: [], markedEaten: []).isLive)
    }

    @Test func liveWithNothingLogged() {
        let plan = Fixtures.engine().liveDayPlan(weekday: 0, logged: [], markedEaten: [])
        #expect(isClose(plan.factor, 1.017832))
        #expect(isClose(plan.rawOpenKcal, 2554.45))
        #expect(plan.leftKcal == 2600)
        #expect(isClose(plan.expectedTotals.kcal, 2587.05))
        #expect(plan.banners == [.logToAdapt])
        #expect(plan.canLogDay)
        #expect(!plan.logsRestOfDay)
    }

    @Test func breakfastLoggedRescalesRestOfDayToTarget() {
        let plan = Fixtures.engine().liveDayPlan(weekday: 0, logged: breakfastLog(), markedEaten: [])
        #expect(isClose(plan.eaten.kcal, 569.35))
        #expect(isClose(plan.leftKcal, 2030.65))
        #expect(isClose(plan.rawOpenKcal, 1992.85))
        #expect(isClose(plan.factor, 1.018968))
        // The rest of the day lands at the 2600 kcal target.
        #expect(isClose(plan.expectedTotals.kcal, 2598.65))
        #expect(plan.meals.map(\.status) == [.eaten, .open, .open, .open, .open])
        #expect(plan.meals[1].items.map(\.grams) == [145, 75, 50, 100, 5, 100, 155])
        #expect(plan.banners == [.eatenSoFar(eatenKcal: plan.eaten.kcal, leftKcal: plan.leftKcal, openMeals: 4)])
        #expect(plan.banners.first?.message == "Al gegeten: 569 kcal. Je hebt nog 2.031 kcal over. "
            + "De 4 resterende maaltijden zijn daarop aangepast.")
        #expect(plan.canLogDay)
        #expect(plan.logsRestOfDay)
    }

    @Test func markedEatenMomentWithoutLog() {
        let plan = Fixtures.engine().liveDayPlan(weekday: 0, logged: breakfastLog(), markedEaten: [.lunch])
        #expect(isClose(plan.rawOpenKcal, 1307.05))
        #expect(isClose(plan.factor, 1.553613))
        #expect(isClose(plan.expectedTotals.kcal, 2591.7))
        #expect(plan.meals.map(\.status) == [.eaten, .markedEaten, .open, .open, .open])
        #expect(plan.meals[1].items.isEmpty)
    }

    @Test func liveFactorHitsLowerBoundAndWarns() {
        let plan = Fixtures.engine().liveDayPlan(weekday: 0, logged: oil(250), markedEaten: [])
        #expect(plan.eaten.kcal == 2210)
        #expect(plan.leftKcal == 390)
        #expect(plan.factor == 0.4)
        #expect(isClose(plan.expectedTotals.kcal, 3262.85))
        // Unslotted logs count as eaten but complete no moment.
        #expect(plan.openMeals.count == 5)
        #expect(plan.banners.count == 2)
        #expect(plan.banners.last == .overEvenWhenScaled(excessKcal: plan.expectedTotals.kcal - 2600))
        #expect(plan.banners.last?.message == "Ook met kleinere porties kom je ongeveer 663 kcal boven je doel. "
            + "Sla eventueel het tussendoortje of de avondsnack over.")
    }

    @Test func targetReached() {
        let plan = Fixtures.engine().liveDayPlan(weekday: 0, logged: oil(400), markedEaten: [])
        #expect(plan.leftKcal == -936)
        #expect(plan.factor == 0.4)
        #expect(plan.banners == [.goalReached(eatenKcal: 3536)])
        #expect(!plan.openMealsNeeded)
        #expect(!plan.canLogDay)
    }

    @Test func allMomentsMarked() {
        let plan = Fixtures.engine().liveDayPlan(
            weekday: 0, logged: [], markedEaten: Set(MealSlot.allCases))
        #expect(plan.factor == 1)
        #expect(plan.rawOpenKcal == 0)
        #expect(plan.openMeals.isEmpty)
        #expect(plan.meals.allSatisfy { $0.status == .markedEaten })
        #expect(!plan.canLogDay)
    }

    // MARK: Log feedback

    @Test func logFeedback() {
        #expect(LogFeedback.message(prefix: "Banaan toegevoegd", eatenKcal: 1400, targetKcal: 2600)
            == "Banaan toegevoegd. Nog 1.200 kcal over")
        #expect(LogFeedback.message(prefix: "Gelogd", eatenKcal: 2625, targetKcal: 2600)
            == "Gelogd. Nog 0 kcal over")
        #expect(LogFeedback.message(prefix: "Gelogd", eatenKcal: 2626, targetKcal: 2600)
            == "Gelogd. Let op: je zit nu 26 kcal boven je doel")
    }
}
