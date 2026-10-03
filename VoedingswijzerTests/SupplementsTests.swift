import Testing
@testable import Voedingswijzer

@Suite("Supplements")
struct SupplementsTests {
    let today = DayKey(year: 2026, month: 10, day: 3)

    func taken(_ list: String...) -> Set<DayKey> {
        Set(list.compactMap { DayKey($0) })
    }

    // MARK: Creatine streak

    @Test func streakIncludesToday() {
        #expect(Supplements.streak(from: today, takenDays: taken("2026-10-03", "2026-10-02", "2026-10-01")) == 3)
    }

    @Test func streakCountsFromYesterdayWhenTodayNotTicked() {
        #expect(Supplements.streak(from: today, takenDays: taken("2026-10-02", "2026-10-01")) == 2)
    }

    @Test func streakBreaksOnMissedYesterday() {
        #expect(Supplements.streak(from: today, takenDays: taken("2026-10-01")) == 0)
    }

    @Test func streakOnlyToday() {
        #expect(Supplements.streak(from: today, takenDays: taken("2026-10-03")) == 1)
    }

    @Test func streakNone() {
        #expect(Supplements.streak(from: today, takenDays: []) == 0)
    }

    @Test func streakAcrossMonthBoundary() {
        let days = taken("2026-10-02", "2026-10-01", "2026-09-30", "2026-09-29")
        #expect(Supplements.streak(from: DayKey(year: 2026, month: 10, day: 2), takenDays: days) == 4)
    }

    @Test func streakIgnoresFutureDays() {
        #expect(Supplements.streak(from: today, takenDays: taken("2026-10-04", "2026-10-03")) == 1)
    }

    @Test func lastSevenDays() {
        let week = Supplements.lastSevenDays(endingOn: today, takenDays: taken("2026-10-03", "2026-09-28", "2026-09-26"))
        #expect(week.map { $0.day.description } == [
            "2026-09-27", "2026-09-28", "2026-09-29", "2026-09-30", "2026-10-01", "2026-10-02", "2026-10-03",
        ])
        #expect(week.map { $0.taken } == [false, true, false, false, false, false, true])
    }

    // MARK: List and settings

    @Test func resolveAppliesSettingsAndAppendsCustom() {
        let custom = CustomSupplement(id: "cs1", name: "Vitamine K2", dose: 75, unit: "µg", nutrient: nil)
        let list = Supplements.resolve(
            defaults: Fixtures.data.supplements, custom: [custom],
            settings: ["creatine": SupplementSetting(dose: 3), "omega3": SupplementSetting(isOn: false), "mag": SupplementSetting(isOn: true)])
        #expect(list.count == 11)
        #expect(list.last?.id == "cs1")
        #expect(list.last?.isCustom == true)
        #expect(list.first { $0.id == "creatine" }?.dose == 3)
        #expect(Supplements.active(list).map(\.id) == ["creatine", "vitd", "multi", "mag", "cs1"])
    }

    @Test func takenSupplementsCountTowardsTotals() {
        let list = Supplements.resolve(defaults: Fixtures.data.supplements, custom: [], settings: [:])
        let totals = DailyTotals.day([], supplements: list, taken: ["vitd", "multi", "creatine"])
        // Prototype: vitamin D3 25 µg + multivitamin 1 tablet.
        #expect(totals[.vitaminD] == 35)
        #expect(totals[.vitaminC] == 80)
        #expect(totals[.vitaminA] == 400)
        #expect(totals[.vitaminB12] == 2.5)
        #expect(totals[.folate] == 200)
        #expect(totals[.iron] == 7)
        #expect(totals[.calcium] == 120)
        #expect(totals[.magnesium] == 60)
        #expect(totals[.zinc] == 5)
        #expect(totals[.potassium] == 0)
        #expect(totals.kcal == 0)
    }

    @Test func multivitaminScalesWithDose() {
        let list = Supplements.resolve(
            defaults: Fixtures.data.supplements, custom: [], settings: ["multi": SupplementSetting(dose: 2)])
        #expect(Supplements.contribution(of: list, taken: ["multi"])[.vitaminC] == 160)
    }

    @Test func switchedOffButTickedStillCounts() {
        let list = Supplements.resolve(
            defaults: Fixtures.data.supplements, custom: [], settings: ["vitd": SupplementSetting(isOn: false)])
        #expect(Supplements.contribution(of: list, taken: ["vitd"])[.vitaminD] == 25)
    }

    @Test func foodAndSupplementsAdd() {
        let list = Supplements.resolve(defaults: Fixtures.data.supplements, custom: [], settings: [:])
        let log = [LoggedFood(food: Fixtures.food("Spinazie"), grams: 200)]
        let totals = DailyTotals.day(log, supplements: list, taken: ["vitd"])
        #expect(isClose(totals.kcal, 46))
        #expect(isClose(totals[.vitaminD], 25))
        #expect(isClose(DailyTotals.food(log)[.vitaminA], 938))
    }

    @Test func customSupplementValidation() {
        #expect(Supplements.validateCustom(name: "  ", unit: "mg", nutrient: nil) == "Geef het supplement een naam")
        #expect(Supplements.validateCustom(name: "Zink", unit: "g", nutrient: .zinc) == "Kies mg als eenheid voor zink")
        #expect(Supplements.validateCustom(name: "D3", unit: "mg", nutrient: .vitaminD)
            == "Kies µg als eenheid voor vitamine d")
        #expect(Supplements.validateCustom(name: "Zink", unit: "mg", nutrient: .zinc) == nil)
        #expect(Supplements.validateCustom(name: "Ashwagandha", unit: "capsule", nutrient: nil) == nil)
    }
}
