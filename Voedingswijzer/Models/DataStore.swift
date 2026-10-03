import Foundation

enum DataStoreError: Error, Equatable, CustomStringConvertible {
    case missingResource(String)
    case unknownFood(meal: String, food: String)
    case missingMeals(menu: String, slot: String)

    var description: String {
        switch self {
        case .missingResource(let name): "Missing seed file \(name).json"
        case .unknownFood(let meal, let food): "Meal \"\(meal)\" uses unknown food \"\(food)\""
        case .missingMeals(let menu, let slot): "Menu \(menu) has fewer than 3 meals for \(slot)"
        }
    }
}

/// Read-only seed data from Resources/Data. Loaded once and shared.
final class DataStore: Sendable {
    let foods: [Food]
    let categories: [String]
    let plans: PlansFile
    let supplements: [Supplement]
    let prices: PricesFile
    let packs: PacksFile
    let stores: StoresFile

    private let foodsByName: [String: Food]

    init(
        foods: FoodsFile, plans: PlansFile, supplements: SupplementsFile,
        prices: PricesFile, packs: PacksFile, stores: StoresFile
    ) throws {
        self.foods = foods.foods
        self.categories = foods.categories
        self.plans = plans
        self.supplements = supplements.supplements
        self.prices = prices
        self.packs = packs
        self.stores = stores
        self.foodsByName = Dictionary(foods.foods.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
        try validate()
    }

    /// Loads all seed files from `bundle`.
    convenience init(bundle: Bundle) throws {
        let decoder = JSONDecoder()
        func load<T: Decodable>(_ name: String) throws -> T {
            let url = bundle.url(forResource: name, withExtension: "json")
                ?? bundle.url(forResource: name, withExtension: "json", subdirectory: "Data")
            guard let url else { throw DataStoreError.missingResource(name) }
            return try decoder.decode(T.self, from: Data(contentsOf: url))
        }
        try self.init(
            foods: load("foods"), plans: load("plans"), supplements: load("supplements"),
            prices: load("prices"), packs: load("packs"), stores: load("stores"))
    }

    /// The bundle that contains the seed JSON for this build (app or Swift package).
    static var resourceBundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }

    /// Loads the seed data shipped with the app.
    static func bundled() throws -> DataStore {
        try DataStore(bundle: resourceBundle)
    }

    func food(named name: String) -> Food? {
        foodsByName[name]
    }

    func meals(_ menu: PlanMenu, _ slot: MealSlot) -> [Meal] {
        plans.menu(menu)?.meals[slot] ?? []
    }

    private func validate() throws {
        for menu in PlanMenu.allCases {
            for slot in MealSlot.allCases {
                let pool = meals(menu, slot)
                guard pool.count >= 3 else {
                    throw DataStoreError.missingMeals(menu: menu.rawValue, slot: slot.rawValue)
                }
                for meal in pool {
                    for item in meal.items where foodsByName[item.food] == nil {
                        throw DataStoreError.unknownFood(meal: meal.name, food: item.food)
                    }
                }
            }
        }
    }
}
