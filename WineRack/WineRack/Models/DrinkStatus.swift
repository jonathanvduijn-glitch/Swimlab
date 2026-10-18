import SwiftUI

// Drinkstatus, berekend uit de drinkperiode en het huidige jaar.
// De volgorde van de cases is ook de volgorde in de lijst (meest urgent eerst).
enum DrinkStatus: Int, CaseIterable, Identifiable {
    case pastPeak
    case drinkThisYear
    case ready
    case wait
    case unknown

    var id: Int { rawValue }

    init(drinkFrom: Int?, drinkBy: Int?, year: Int = DrinkStatus.currentYear) {
        if let drinkBy, drinkBy < year {
            self = .pastPeak
        } else if let drinkBy, drinkBy == year {
            self = .drinkThisYear
        } else if let drinkFrom, drinkFrom > year {
            self = .wait
        } else if drinkFrom != nil || drinkBy != nil {
            self = .ready
        } else {
            self = .unknown
        }
    }

    static var currentYear: Int {
        Calendar.current.component(.year, from: .now)
    }

    var title: String {
        switch self {
        case .pastPeak: "Over zijn hoogtepunt"
        case .drinkThisYear: "Dit jaar opdrinken"
        case .ready: "Op dronk"
        case .wait: "Nog laten liggen"
        case .unknown: "Onbekend"
        }
    }

    var color: Color {
        switch self {
        case .pastPeak: .red
        case .drinkThisYear: .orange
        case .ready: .green
        case .wait: .blue
        case .unknown: .gray
        }
    }

    var icon: String {
        switch self {
        case .pastPeak: "exclamationmark.triangle.fill"
        case .drinkThisYear: "clock.fill"
        case .ready: "checkmark.circle.fill"
        case .wait: "hourglass"
        case .unknown: "questionmark.circle"
        }
    }
}
