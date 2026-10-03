import Foundation
import Testing
@testable import Voedingswijzer

@Suite("Seed data")
struct DataStoreTests {
    let data = Fixtures.data

    @Test func loadsAllFoods() {
        #expect(data.foods.count == 134)
        #expect(Set(data.foods.map(\.name)).count == 134)
        #expect(data.categories.first == "Alles")
        #expect(data.categories.last == "Eigen")
    }

    @Test func foodValuesMatchPrototype() {
        let spinach = Fixtures.food("Spinazie")
        #expect(spinach.category == "Groente")
        #expect(spinach.kcal == 23)
        #expect(spinach.per100g[.protein] == 2.9)
        #expect(spinach.per100g[.vitaminA] == 469)
        #expect(spinach.per100g[.zinc] == 0.5)
    }

    @Test(arguments: [
        (PlanMenu.budget, [MealSlot.breakfast: 9, .lunch: 9, .snack: 6, .dinner: 14, .eveningSnack: 6], 44),
        (PlanMenu.varied, [MealSlot.breakfast: 9, .lunch: 12, .snack: 9, .dinner: 21, .eveningSnack: 9], 60),
    ])
    func mealCounts(menu: PlanMenu, perSlot: [MealSlot: Int], total: Int) {
        for slot in MealSlot.allCases {
            #expect(data.meals(menu, slot).count == perSlot[slot])
        }
        #expect(MealSlot.allCases.reduce(0) { $0 + data.meals(menu, $1).count } == total)
    }

    @Test func menuNames() {
        #expect(data.plans.menu(.budget)?.name == "Gangbaar & goedkoop")
        #expect(data.plans.menu(.varied)?.name == "Gevarieerd")
        #expect(data.plans.days.count == 7)
        #expect(data.plans.slots.map(\.id) == MealSlot.allCases)
    }

    @Test func everyMealIngredientIsAKnownFood() {
        for menu in PlanMenu.allCases {
            for slot in MealSlot.allCases {
                for meal in data.meals(menu, slot) {
                    for item in meal.items {
                        #expect(data.food(named: item.food) != nil, "\(meal.name): \(item.food)")
                    }
                }
            }
        }
    }

    @Test func supplementsPricesPacksStores() {
        #expect(data.supplements.count == 10)
        #expect(data.supplements.first?.id == "creatine")
        #expect(data.supplements.filter(\.defaultOn).map(\.id) == ["creatine", "vitd", "multi", "omega3"])
        #expect(data.prices.perKg.count == 134)
        #expect(data.prices.fallbackPerKg == 5)
        #expect(data.packs.packs.count == 119)
        #expect(data.packs.aisles.count == 12)
        #expect(data.packs.fallback == Pack(
            aisle: "Ontbijt & beleg", singular: "verpakking", plural: "verpakkingen", grams: 500, conversion: 1))
        #expect(data.stores.stores.count == 13)
        #expect(data.stores.defaultStores == ["Albert Heijn", "Jumbo", "Lidl", "ALDI", "Dirk"])
    }

    @Test func nutrientsRoundTripThroughJSON() throws {
        let original = Fixtures.food("Broccoli").per100g
        let decoded = try JSONDecoder().decode(Nutrients.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }

    @Test func unknownMealFoodIsRejected() throws {
        let plans = PlansFile(
            slots: data.plans.slots, days: data.plans.days,
            menus: Dictionary(uniqueKeysWithValues: PlanMenu.allCases.map { menu in
                (menu.rawValue, PlansFile.MenuInfo(name: menu.rawValue, meals: Dictionary(
                    uniqueKeysWithValues: MealSlot.allCases.map { slot in
                        (slot, Array(repeating: Meal(name: "Test", items: [MealIngredient(food: "Bestaat niet", grams: 1)]), count: 3))
                    })))
            }))
        #expect(throws: DataStoreError.unknownFood(meal: "Test", food: "Bestaat niet")) {
            try DataStore(
                foods: FoodsFile(nutrientKeys: Nutrient.allCases, categories: data.categories, foods: data.foods),
                plans: plans, supplements: SupplementsFile(supplements: data.supplements), prices: data.prices,
                packs: data.packs, stores: data.stores)
        }
    }
}
