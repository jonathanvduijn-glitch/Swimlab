import Foundation
import Testing
@testable import Voedingswijzer

enum Fixtures {
    /// The bundled seed data, loaded once for all tests.
    static let data: DataStore = {
        do {
            return try DataStore.bundled()
        } catch {
            fatalError("Seed data failed to load: \(error)")
        }
    }()

    static let referenceTargets = Targets(profile: .reference)

    /// Monday 5 October 2026: plan weekday 0.
    static let monday = DayKey(year: 2026, month: 10, day: 5)

    static func engine(
        _ menu: PlanMenu = .budget, choices: PlanChoices = PlanChoices(), autoScale: Bool = true
    ) -> PlanEngine {
        PlanEngine(
            data: data, menu: menu, choices: choices, targetKcal: Double(referenceTargets.kcal), autoScale: autoScale)
    }

    static func food(_ name: String) -> Food {
        guard let food = data.food(named: name) else { fatalError("Unknown food \(name)") }
        return food
    }
}

func isClose(_ a: Double, _ b: Double, tolerance: Double = 1e-6) -> Bool {
    abs(a - b) <= tolerance
}
