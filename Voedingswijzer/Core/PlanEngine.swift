import Foundation

/// A logged food: a snapshot of its nutrients per 100 g, so old days never change.
struct LoggedFood: Hashable, Sendable {
    var name: String
    var grams: Double
    var per100g: Nutrients
    /// The plan moment it was logged for, if it was logged from today's live plan.
    var slot: MealSlot?

    init(name: String, grams: Double, per100g: Nutrients, slot: MealSlot? = nil) {
        self.name = name
        self.grams = grams
        self.per100g = per100g
        self.slot = slot
    }

    init(food: Food, grams: Double, slot: MealSlot? = nil) {
        self.init(name: food.name, grams: grams, per100g: food.per100g, slot: slot)
    }

    var nutrients: Nutrients { per100g.scaled(toGrams: grams) }
}

enum DailyTotals {
    /// Sum of all logged foods (prototype `totals(day, false)`).
    static func food(_ entries: [LoggedFood]) -> Nutrients {
        entries.reduce(Nutrients()) { $0 + $1.nutrients }
    }

    /// Logged foods plus the supplements taken that day (prototype `totals(day)`).
    static func day(
        _ entries: [LoggedFood], supplements: [ResolvedSupplement], taken: Set<String>
    ) -> Nutrients {
        food(entries) + Supplements.contribution(of: supplements, taken: taken)
    }
}

/// The user's chosen option (0…2) per weekday and moment, for one menu.
struct PlanChoices: Hashable, Codable, Sendable {
    private var choices: [Int: [MealSlot: Int]]

    init(_ choices: [Int: [MealSlot: Int]] = [:]) {
        self.choices = choices
    }

    /// The chosen option index; 0 when nothing (valid) was chosen.
    func choice(weekday: Int, slot: MealSlot) -> Int {
        let index = choices[weekday]?[slot] ?? 0
        return (0..<PlanEngine.optionsPerSlot).contains(index) ? index : 0
    }

    mutating func choose(_ index: Int, weekday: Int, slot: MealSlot) {
        choices[weekday, default: [:]][slot] = index
    }
}

/// One ingredient line in the plan, scaled to a portion.
struct PlanItem: Hashable, Sendable {
    let name: String
    let grams: Double
    let per100g: Nutrients

    var nutrients: Nutrients { per100g.scaled(toGrams: grams) }
}

struct PlannedMeal: Hashable, Sendable {
    enum Status: Hashable, Sendable {
        /// Still to eat; `items` are the scaled portions.
        case open
        /// Logged for this moment; `items` are what was logged.
        case eaten
        /// "Al gegeten, zelf ingevoerd": eaten, nothing logged for this moment.
        case markedEaten
    }

    let slot: MealSlot
    let items: [PlanItem]
    let status: Status

    var isDone: Bool { status != .open }
    var totals: Nutrients { items.reduce(Nutrients()) { $0 + $1.nutrients } }
}

/// Messages above the live plan for today.
enum PlanBanner: Hashable, Sendable {
    case goalReached(eatenKcal: Double)
    case eatenSoFar(eatenKcal: Double, leftKcal: Double, openMeals: Int)
    case logToAdapt
    /// Even with smaller portions the day ends this many kcal over the target.
    case overEvenWhenScaled(excessKcal: Double)

    var isWarning: Bool {
        switch self {
        case .goalReached, .overEvenWhenScaled: true
        case .eatenSoFar, .logToAdapt: false
        }
    }

    /// The banner text, as in the prototype.
    var message: String {
        switch self {
        case .goalReached(let eaten):
            return "Je dagdoel is bereikt (\(DutchNumber.format(eaten)) kcal gegeten). Heb je nog honger, "
                + "kies dan iets lichts en eiwitrijks, zoals 250 g magere kwark (ongeveer 145 kcal)."
        case .eatenSoFar(let eaten, let left, let open):
            var text = "Al gegeten: \(DutchNumber.format(eaten)) kcal. Je hebt nog \(DutchNumber.format(left)) kcal over."
            if open == 1 {
                text += " De resterende maaltijd is daarop aangepast."
            } else if open > 1 {
                text += " De \(open) resterende maaltijden zijn daarop aangepast."
            }
            return text
        case .logToAdapt:
            return "Log wat je eet, dan past de rest van de dag zich automatisch aan op wat je nog over hebt."
        case .overEvenWhenScaled(let excess):
            return "Ook met kleinere porties kom je ongeveer \(DutchNumber.format(excess)) kcal boven je doel. "
                + "Sla eventueel het tussendoortje of de avondsnack over."
        }
    }
}

/// A plan day. For today (the log day) it is "live": eaten moments are done and the rest is
/// rescaled to what is left of the kcal target.
struct DayPlan: Hashable, Sendable {
    let weekday: Int
    let isLive: Bool
    /// Portion factor applied to the open meals.
    let factor: Double
    let meals: [PlannedMeal]
    /// Everything logged today, live plans only.
    let eaten: Nutrients
    /// kcal target minus eaten kcal, live plans only.
    let leftKcal: Double
    /// Unscaled kcal of the open meals, live plans only.
    let rawOpenKcal: Double
    let targetKcal: Double

    var openMeals: [PlannedMeal] { meals.filter { !$0.isDone } }

    /// Expected day totals: open meals plus, when live, everything already eaten.
    var expectedTotals: Nutrients {
        let open = openMeals.reduce(Nutrients()) { $0 + $1.totals }
        return isLive ? open + eaten : open
    }

    /// Open meals are shown as "niet meer nodig vandaag" once the target is reached.
    var openMealsNeeded: Bool { !(isLive && leftKcal <= 0) }

    var banners: [PlanBanner] {
        guard isLive else { return [] }
        var banners: [PlanBanner] = []
        let eatenKcal = eaten.kcal
        if leftKcal <= 0 {
            banners.append(.goalReached(eatenKcal: eatenKcal))
        } else if eatenKcal > 0 {
            banners.append(.eatenSoFar(eatenKcal: eatenKcal, leftKcal: leftKcal, openMeals: openMeals.count))
        } else {
            banners.append(.logToAdapt)
        }
        let expected = expectedTotals.kcal
        if leftKcal > 0 && expected > targetKcal + 50 {
            banners.append(.overEvenWhenScaled(excessKcal: expected - targetKcal))
        }
        return banners
    }

    /// Whether the "log the (rest of the) day" button is shown.
    var canLogDay: Bool { !(isLive && (openMeals.isEmpty || leftKcal <= 0)) }

    /// True when the button logs only the rest of today ("Rest van de dag loggen").
    var logsRestOfDay: Bool { isLive && openMeals.count < MealSlot.allCases.count }
}

/// Weekly meal plan calculations (prototype `optsFor`, `planFactor`, `portion`, `dayPlan`).
struct PlanEngine: Sendable {
    static let optionsPerSlot = 3
    static let dayFactorRange = 0.7...1.4
    static let liveFactorRange = 0.4...1.6
    static let minimumPortion = 5.0

    let data: DataStore
    let menu: PlanMenu
    let choices: PlanChoices
    let targetKcal: Double
    /// "Porties afstemmen op mijn kcal-doel".
    let autoScale: Bool

    init(data: DataStore, menu: PlanMenu, choices: PlanChoices, targetKcal: Double, autoScale: Bool = true) {
        self.data = data
        self.menu = menu
        self.choices = choices
        self.targetKcal = targetKcal
        self.autoScale = autoScale
    }

    // MARK: Pure rules

    /// Indices into a pool of `poolSize` meals for the three options on `weekday` (Monday = 0).
    static func optionIndices(weekday w: Int, poolSize n: Int) -> [Int] {
        (0..<optionsPerSlot).map { i in (w * 3 + i + (w * 3) / n) % n }
    }

    /// Day factor: target ÷ unscaled kcal, limited to 0.7–1.4; 1 when auto-scaling is off.
    static func dayFactor(targetKcal: Double, rawKcal: Double, autoScale: Bool = true) -> Double {
        guard autoScale else { return 1 }
        return clamp(targetKcal / rawKcal, to: dayFactorRange)
    }

    /// Live factor for the rest of today: kcal left ÷ unscaled kcal of the open meals, limited to 0.4–1.6.
    static func liveFactor(leftKcal: Double, rawOpenKcal: Double, autoScale: Bool = true) -> Double {
        guard autoScale, rawOpenKcal > 0 else { return 1 }
        return clamp(leftKcal / rawOpenKcal, to: liveFactorRange)
    }

    /// A scaled portion, rounded to 5 g and at least 5 g.
    static func portion(grams: Double, factor: Double) -> Double {
        max(minimumPortion, jsRound(grams * factor / 5) * 5)
    }

    private static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(range.upperBound, max(range.lowerBound, value))
    }

    // MARK: Plan data

    /// The three meal options for a moment on `weekday`.
    func options(_ slot: MealSlot, weekday: Int) -> [Meal] {
        let pool = data.meals(menu, slot)
        guard !pool.isEmpty else { return [] }
        return Self.optionIndices(weekday: weekday, poolSize: pool.count).map { pool[$0] }
    }

    /// The chosen meal for a moment.
    func chosenMeal(_ slot: MealSlot, weekday: Int) -> Meal? {
        let meals = options(slot, weekday: weekday)
        let index = choices.choice(weekday: weekday, slot: slot)
        return meals.indices.contains(index) ? meals[index] : nil
    }

    /// Unscaled kcal of the chosen meals for the given moments.
    func rawKcal(weekday: Int, slots: [MealSlot] = MealSlot.allCases) -> Double {
        // Summed item by item in plan order, exactly like the prototype, so factors match to the last bit.
        let items = slots.flatMap { chosenMeal($0, weekday: weekday)?.items ?? [] }
        return items.reduce(0) { sum, item in sum + (data.food(named: item.food)?.kcal ?? 0) * item.grams / 100 }
    }

    /// The base day factor for `weekday`.
    func dayFactor(weekday: Int) -> Double {
        Self.dayFactor(targetKcal: targetKcal, rawKcal: rawKcal(weekday: weekday), autoScale: autoScale)
    }

    /// The chosen meal for a moment, scaled by `factor`.
    func items(_ slot: MealSlot, weekday: Int, factor: Double) -> [PlanItem] {
        guard let meal = chosenMeal(slot, weekday: weekday) else { return [] }
        return meal.items.compactMap { item in
            guard let food = data.food(named: item.food) else { return nil }
            return PlanItem(name: food.name, grams: Self.portion(grams: item.grams, factor: factor), per100g: food.per100g)
        }
    }

    // MARK: Day plans

    /// A plan day that is not today: every moment open, scaled by the base day factor.
    func dayPlan(weekday: Int) -> DayPlan {
        let factor = dayFactor(weekday: weekday)
        let meals = MealSlot.allCases.map {
            PlannedMeal(slot: $0, items: items($0, weekday: weekday, factor: factor), status: .open)
        }
        return DayPlan(
            weekday: weekday, isLive: false, factor: factor, meals: meals, eaten: .zero, leftKcal: 0,
            rawOpenKcal: 0, targetKcal: targetKcal)
    }

    /// Today's plan. Moments with logged items, or marked as eaten, are done; the rest is
    /// rescaled to the kcal that is left after everything logged today.
    func liveDayPlan(weekday: Int, logged: [LoggedFood], markedEaten: Set<MealSlot>) -> DayPlan {
        let done = markedEaten.union(logged.compactMap(\.slot))
        let eaten = DailyTotals.food(logged)
        let openSlots = MealSlot.allCases.filter { !done.contains($0) }
        let raw = rawKcal(weekday: weekday, slots: openSlots)
        let left = targetKcal - eaten.kcal
        let factor = Self.liveFactor(leftKcal: left, rawOpenKcal: raw, autoScale: autoScale)

        let meals = MealSlot.allCases.map { slot -> PlannedMeal in
            guard done.contains(slot) else {
                return PlannedMeal(slot: slot, items: items(slot, weekday: weekday, factor: factor), status: .open)
            }
            let loggedItems = logged.filter { $0.slot == slot }.map {
                PlanItem(name: $0.name, grams: $0.grams, per100g: $0.per100g)
            }
            return PlannedMeal(slot: slot, items: loggedItems, status: loggedItems.isEmpty ? .markedEaten : .eaten)
        }
        return DayPlan(
            weekday: weekday, isLive: true, factor: factor, meals: meals, eaten: eaten, leftKcal: left,
            rawOpenKcal: raw, targetKcal: targetKcal)
    }

    /// The plan for `weekday`; live when it is the weekday of the log day.
    func dayPlan(weekday: Int, logDay: DayKey, logged: [LoggedFood], markedEaten: Set<MealSlot>) -> DayPlan {
        weekday == logDay.weekdayIndex
            ? liveDayPlan(weekday: weekday, logged: logged, markedEaten: markedEaten)
            : dayPlan(weekday: weekday)
    }

    /// All scaled items for the week, using each day's base factor (input for the shopping list).
    func weekItems() -> [PlanItem] {
        (0..<7).flatMap { weekday in
            let factor = dayFactor(weekday: weekday)
            return MealSlot.allCases.flatMap { items($0, weekday: weekday, factor: factor) }
        }
    }
}

/// Feedback after logging (prototype `overCheck()`).
enum LogFeedback {
    /// More than this many kcal over the target counts as "over".
    static let tolerance = 25.0

    static func isOverTarget(eatenKcal: Double, targetKcal: Double) -> Bool {
        eatenKcal > targetKcal + tolerance
    }

    /// E.g. "Banaan toegevoegd. Nog 1.200 kcal over".
    static func message(prefix: String, eatenKcal: Double, targetKcal: Double) -> String {
        if isOverTarget(eatenKcal: eatenKcal, targetKcal: targetKcal) {
            return "\(prefix). Let op: je zit nu \(DutchNumber.format(eatenKcal - targetKcal)) kcal boven je doel"
        }
        return "\(prefix). Nog \(DutchNumber.format(max(0, targetKcal - eatenKcal))) kcal over"
    }
}
