import Foundation

// Waar de fles ligt.
enum WineLocation: String, CaseIterable, Identifiable {
    case fridge = "Koeling"
    case cabinet = "Kast"
    case cellar = "Kelder"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fridge: "snowflake"
        case .cabinet: "cabinet"
        case .cellar: "archivebox"
        }
    }
}

// Filter bovenaan de lijst: alles of één locatie.
enum LocationFilter: String, CaseIterable, Identifiable {
    case all = "Alles"
    case fridge = "Koeling"
    case cabinet = "Kast"
    case cellar = "Kelder"

    var id: String { rawValue }

    // Bij "Alles" is er geen locatie (nil).
    var location: WineLocation? { WineLocation(rawValue: rawValue) }
}
