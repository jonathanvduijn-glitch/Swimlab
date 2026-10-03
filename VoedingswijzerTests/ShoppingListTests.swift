import Testing
@testable import Voedingswijzer

@Suite("Shopping list")
struct ShoppingListTests {
    let defaultStores = Set(Fixtures.data.stores.defaultStores)

    func makeList(_ menu: PlanMenu = .budget, stores: Set<String>? = nil) -> ShoppingList {
        ShoppingList(items: Fixtures.engine(menu).weekItems(), data: Fixtures.data, selectedStores: stores ?? defaultStores)
    }

    // MARK: Pack counts

    @Test(arguments: [
        (1035.0, 800.0, 2),   // bread: 1.29 packs
        (1205, 500, 3),       // tomatoes: 2.41
        (530, 400, 2),        // cucumbers: 1.325
        (2845, 1000, 3),      // quark: 2.845
        (1715, 1000, 2),      // milk: 1.715
        (1080, 1000, 1),      // exactly 8 % over one pack still fits
        (1081, 1000, 2),      // just over the tolerance
        (2000, 1000, 2),
        (920, 2000, 1),
        (1, 500, 1),          // always at least one pack
        (0, 500, 1),
    ])
    func packCount(needed: Double, pack: Double, expected: Int) {
        #expect(ShoppingList.packCount(neededGrams: needed, packGrams: pack) == expected)
    }

    @Test func conversionFromBoughtToPlanWeight() {
        // 415 g cooked rice ÷ 2.8 = 148 g dry → 1 bag of 1 kg; price = 1000 × 2.8 / 1000 × € 0.75.
        let rice = makeList().rows.first { $0.foodName == "Witte rijst (gekookt)" }
        #expect(rice?.grams == 415)
        #expect(isClose(rice?.neededGrams ?? 0, 415 / 2.8))
        #expect(rice?.packCount == 1)
        #expect(isClose(rice?.cost ?? 0, 2.1))
        #expect(rice?.label == "1 zak rijst (1 kg)")
        #expect(rice?.displayName == "Witte rijst")
    }

    // MARK: Whole list against the prototype

    @Test func budgetListMatchesPrototype() {
        let list = makeList()
        let byName = Dictionary(uniqueKeysWithValues: list.rows.map { ($0.foodName, $0) })
        #expect(list.rows.count == PrototypeReference.budgetShopping.count)
        for expected in PrototypeReference.budgetShopping {
            guard let row = byName[expected.name] else {
                Issue.record("Missing \(expected.name)")
                continue
            }
            #expect(row.grams == expected.grams, "\(expected.name)")
            #expect(row.aisle == expected.aisle, "\(expected.name)")
            #expect(row.label == expected.label, "\(expected.name)")
            #expect(isClose(row.cost, expected.cost, tolerance: 1e-4), "\(expected.name)")
            #expect(isClose(row.usedCost, expected.used, tolerance: 1e-4), "\(expected.name)")
        }
        #expect(isClose(list.checkoutTotal, PrototypeReference.budgetCheckout, tolerance: 1e-3))
        #expect(isClose(list.eatenTotal, PrototypeReference.budgetEaten, tolerance: 1e-3))
    }

    @Test func variedListMatchesPrototype() {
        let list = makeList(.varied)
        #expect(list.rows.count == PrototypeReference.variedRowCount)
        #expect(isClose(list.checkoutTotal, PrototypeReference.variedCheckout, tolerance: 1e-3))
        #expect(isClose(list.eatenTotal, PrototypeReference.variedEaten, tolerance: 1e-3))
    }

    @Test func groupedByAisleInAisleOrder() {
        let list = makeList()
        #expect(list.sections.map { $0.aisle } == PrototypeReference.budgetAisles)
        let dairy = list.sections.first { $0.aisle == "Zuivel & eieren" }?.rows.map(\.foodName)
        #expect(dairy == [
            "Ei (gekookt)", "Eiwit van ei", "Halfvolle melk", "Halvarine (verrijkt)", "Hüttenkäse",
            "Magere kwark", "Magere yoghurt",
        ])
    }

    // MARK: Stores and prices

    @Test func storeComparisonCheapestFirst() {
        let list = makeList()
        #expect(list.stores.map(\.name) == PrototypeReference.budgetStores.map { $0.name })
        for (estimate, expected) in zip(list.stores, PrototypeReference.budgetStores) {
            #expect(isClose(estimate.checkoutTotal, expected.checkout, tolerance: 1e-3))
            #expect(isClose(estimate.eatenTotal, expected.eaten, tolerance: 1e-3))
        }
        #expect(list.cheapest?.name == "Dirk")
        #expect(isClose(list.priceFactor, 0.91))
        let bread = list.rows.first { $0.foodName == "Volkorenbrood" }
        #expect(bread?.label == "2 broden (800 g)")
        #expect(isClose(bread.map(list.price) ?? 0, 4.16 * 0.91))
    }

    @Test func equalIndexKeepsStoreOrder() {
        // Dirk and Nettorama are both −9 %; Dirk comes first in stores.json.
        #expect(makeList(stores: ["Nettorama", "Dirk", "Jumbo"]).stores.map(\.name) == ["Dirk", "Nettorama", "Jumbo"])
    }

    @Test func noStoresSelected() {
        let list = makeList(stores: [])
        #expect(list.stores.isEmpty)
        #expect(list.cheapest == nil)
        #expect(list.priceFactor == 1)
    }

    @Test func fallbacksForUnknownProducts() {
        let custom = Food(name: "Mijn reep", category: "Eigen", per100g: Nutrients([.kcal: 400]))
        #expect(ShoppingList.pricePerKg(of: custom, in: Fixtures.data.prices) == 5)
        let pack = ShoppingList.pack(for: custom, in: Fixtures.data.packs)
        #expect(pack == Fixtures.data.packs.fallback)

        let vegetable = Food(name: "Pastinaak", category: "Groente", per100g: Nutrients([.kcal: 75]))
        #expect(ShoppingList.pricePerKg(of: vegetable, in: Fixtures.data.prices) == 3)
        #expect(ShoppingList.pack(for: vegetable, in: Fixtures.data.packs).aisle == "Groente & fruit")
        #expect(ShoppingList.pack(for: vegetable, in: Fixtures.data.packs).singular == "verpakking")
    }

    // MARK: Rows

    @Test func displayNameDropsPreparation() {
        let row = { (name: String) in
            ShoppingRow(
                foodName: name, grams: 100, pack: Fixtures.data.packs.fallback, neededGrams: 100, packCount: 1,
                cost: 1, usedCost: 1)
        }
        #expect(row("Kipfilet (gebakken)").displayName == "Kipfilet")
        #expect(row("Zalm (gegaard)").displayName == "Zalm")
        #expect(row("Ei (gekookt)").displayName == "Ei")
        #expect(row("Kipfilet (beleg)").displayName == "Kipfilet (beleg)")
    }

    @Test func leftoverAndTicks() {
        let list = makeList()
        let kwark = list.rows.first { $0.foodName == "Magere kwark" }
        #expect(isClose(kwark?.leftoverFraction ?? 0, 1 - 2845.0 / 3000))
        #expect(list.tickedCount(["Magere kwark", "Volkorenbrood", "Niet op de lijst"]) == 2)
        #expect(list.tickedCount([]) == 0)
    }
}
