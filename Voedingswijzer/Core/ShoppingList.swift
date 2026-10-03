import Foundation

/// One product on the shopping list.
struct ShoppingRow: Hashable, Sendable, Identifiable {
    let foodName: String
    /// Grams needed this week, as weighed in the plan.
    let grams: Double
    let pack: Pack
    /// Grams needed as bought (plan grams ÷ conversion).
    let neededGrams: Double
    let packCount: Int
    /// € for `packCount` packs at the average price (index 0).
    let cost: Double
    /// € worth of what is actually eaten this week, at the average price.
    let usedCost: Double

    var id: String { foodName }
    var aisle: String { pack.aisle }

    /// E.g. "2 broden (800 g)".
    var label: String { "\(packCount) \(packCount == 1 ? pack.singular : pack.plural)" }

    /// Name without "(gebakken)", "(gekookt)" or "(gegaard)", since you buy it raw.
    var displayName: String {
        guard let range = foodName.range(of: #" \((gebakken|gekookt|gegaard)\)"#, options: .regularExpression)
        else { return foodName }
        return foodName.replacingCharacters(in: range, with: "")
    }

    /// Share of the bought packs left over after this week, 0–1.
    var leftoverFraction: Double {
        max(0, 1 - neededGrams / (Double(packCount) * pack.grams))
    }
}

/// Estimated weekly cost at one supermarket.
struct StoreEstimate: Hashable, Sendable {
    let name: String
    let index: Double
    /// "aan de kassa": everything on the list.
    let checkoutTotal: Double
    /// "deze week opgegeten": what is eaten this week.
    let eatenTotal: Double
}

/// The weekly shopping list (prototype `shopList()`).
struct ShoppingList: Sendable {
    /// Packs slightly under the need still count: 8 % of a pack is tolerated.
    static let packTolerance = 0.08

    let rows: [ShoppingRow]
    /// Sections in aisle order; rows sorted by name within a section.
    let sections: [(aisle: String, rows: [ShoppingRow])]
    /// Average price (index 0).
    let checkoutTotal: Double
    let eatenTotal: Double
    /// The selected stores, cheapest first.
    let stores: [StoreEstimate]

    var cheapest: StoreEstimate? { stores.first }

    /// Multiplier for row prices at the cheapest selected store.
    var priceFactor: Double { cheapest.map { 1 + $0.index / 100 } ?? 1 }

    /// Row price at the cheapest selected store.
    func price(of row: ShoppingRow) -> Double { row.cost * priceFactor }

    func tickedCount(_ ticked: Set<String>) -> Int {
        rows.filter { ticked.contains($0.foodName) }.count
    }

    // MARK: Rules

    /// Number of packs: max(1, ceil(need ÷ pack − 0.08)).
    static func packCount(neededGrams: Double, packGrams: Double) -> Int {
        max(1, Int((neededGrams / packGrams - packTolerance).rounded(.up)))
    }

    static func pack(for food: Food, in packs: PacksFile) -> Pack {
        if let pack = packs.packs[food.name] { return pack }
        let fallback = packs.fallback
        return Pack(
            aisle: packs.categoryAisles[food.category] ?? fallback.aisle, singular: fallback.singular,
            plural: fallback.plural, grams: fallback.grams, conversion: fallback.conversion)
    }

    /// € per kg as weighed in the plan.
    static func pricePerKg(of food: Food, in prices: PricesFile) -> Double {
        prices.perKg[food.name] ?? prices.categoryPerKg[food.category] ?? prices.fallbackPerKg
    }

    // MARK: Building

    /// Builds the list from the week's plan items for the stores the user selected.
    init(items: [PlanItem], data: DataStore, selectedStores: Set<String>) {
        // Totals per food, in first-seen order.
        var order: [String] = []
        var grams: [String: Double] = [:]
        for item in items {
            if grams[item.name] == nil { order.append(item.name) }
            grams[item.name, default: 0] += item.grams
        }

        let rows = order.compactMap { name -> ShoppingRow? in
            guard let food = data.food(named: name), let total = grams[name] else { return nil }
            let pack = Self.pack(for: food, in: data.packs)
            let needed = total / pack.conversion
            let count = Self.packCount(neededGrams: needed, packGrams: pack.grams)
            let pricePerKg = Self.pricePerKg(of: food, in: data.prices)
            let packPrice = pack.grams * pack.conversion / 1000 * pricePerKg
            return ShoppingRow(
                foodName: name, grams: total, pack: pack, neededGrams: needed, packCount: count,
                cost: Double(count) * packPrice, usedCost: total / 1000 * pricePerKg)
        }

        let checkout = rows.reduce(0) { $0 + $1.cost }
        let eaten = rows.reduce(0) { $0 + $1.usedCost }
        let estimates = data.stores.stores.enumerated()
            .filter { selectedStores.contains($0.element.name) }
            .map { offset, store in
                let factor = 1 + store.index / 100
                return (offset, StoreEstimate(
                    name: store.name, index: store.index, checkoutTotal: checkout * factor, eatenTotal: eaten * factor))
            }
            // Stable: equal totals keep the stores.json order, like the prototype's Array.sort.
            .sorted { $0.1.checkoutTotal != $1.1.checkoutTotal ? $0.1.checkoutTotal < $1.1.checkoutTotal : $0.0 < $1.0 }
            .map { $0.1 }

        let dutch = Locale(identifier: "nl_NL")
        let sections = data.packs.aisles.compactMap { aisle -> (aisle: String, rows: [ShoppingRow])? in
            let inAisle = rows.filter { $0.aisle == aisle }
                .sorted { $0.foodName.compare($1.foodName, locale: dutch) == .orderedAscending }
            return inAisle.isEmpty ? nil : (aisle, inAisle)
        }

        self.rows = sections.flatMap { $0.rows }
        self.sections = sections
        self.checkoutTotal = checkout
        self.eatenTotal = eaten
        self.stores = estimates
    }
}
