import SwiftUI

// Soort wijn. De Nederlandse naam is ook de waarde die we opslaan.
enum WineType: String, CaseIterable, Identifiable {
    case red = "Rood"
    case white = "Wit"
    case rose = "Rosé"
    case sparkling = "Mousserend"
    case dessert = "Dessert"
    case fortified = "Versterkt"
    case other = "Overig"

    var id: String { rawValue }

    // Kleur van het glas-icoon in de lijst.
    var color: Color {
        switch self {
        case .red: Color(red: 0.55, green: 0.05, blue: 0.15)
        case .white: Color(red: 0.85, green: 0.72, blue: 0.30)
        case .rose: .pink
        case .sparkling: .yellow
        case .dessert: .orange
        case .fortified: .brown
        case .other: .gray
        }
    }

    // Zet tekst van Claude (bijv. "rose" of "Rosé") om naar een type.
    static func from(_ text: String?) -> WineType? {
        guard let text else { return nil }
        let wanted = normalized(text)
        return allCases.first { normalized($0.rawValue) == wanted }
    }

    private static func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
