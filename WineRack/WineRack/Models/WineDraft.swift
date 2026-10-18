import Foundation

// Tijdelijke kopie van een wijn voor het formulier.
// Pas bij "Bewaar" worden de waarden in de echte Wine gezet.
struct WineDraft {
    var name = ""
    var producer = ""
    var vintage: Int?
    var grape = ""
    var region = ""
    var country = ""
    var type: WineType = .red
    var location: WineLocation = .cellar
    var quantity = 1
    var drinkFrom: Int?
    var drinkBy: Int?
    var pairings: [String] = []
    var notes = ""
    var rating = 0
    var imageData: Data?

    init() {}

    // Formulier vullen met een bestaande wijn (voor "Wijzig").
    init(wine: Wine) {
        name = wine.name
        producer = wine.producer
        vintage = wine.vintage
        grape = wine.grape
        region = wine.region
        country = wine.country
        type = wine.type
        location = wine.location
        quantity = wine.quantity
        drinkFrom = wine.drinkFrom
        drinkBy = wine.drinkBy
        pairings = wine.pairings
        notes = wine.notes
        rating = wine.rating
        imageData = wine.labelImage
    }

    // Jaartallen buiten dit bereik zijn vrijwel zeker een tikfout.
    static let validYears = 1800...2200

    var hasName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Uitleg als een jaartal niet klopt; nil als alles in orde is.
    var yearProblem: String? {
        let years = [vintage, drinkFrom, drinkBy].compactMap { $0 }
        if years.contains(where: { !Self.validYears.contains($0) }) {
            return "Vul jaartallen met 4 cijfers in, bijvoorbeeld 2030."
        }
        if let drinkFrom, let drinkBy, drinkFrom > drinkBy {
            return "\"Vanaf\" moet vóór of gelijk aan \"Vóór\" liggen."
        }
        return nil
    }

    // Bewaren mag als er een naam is en de jaartallen kloppen.
    var canSave: Bool {
        hasName && yearProblem == nil
    }

    // Waarden uit het formulier overzetten naar de wijn.
    func apply(to wine: Wine) {
        wine.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        wine.producer = producer.trimmingCharacters(in: .whitespacesAndNewlines)
        wine.vintage = vintage
        wine.grape = grape.trimmingCharacters(in: .whitespacesAndNewlines)
        wine.region = region.trimmingCharacters(in: .whitespacesAndNewlines)
        wine.country = country.trimmingCharacters(in: .whitespacesAndNewlines)
        wine.type = type
        wine.location = location
        wine.quantity = max(0, quantity)
        wine.drinkFrom = drinkFrom
        wine.drinkBy = drinkBy
        wine.pairings = pairings
        wine.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        wine.rating = min(max(rating, 0), 5)
        // Miniatuur alleen opnieuw maken als de foto veranderd is.
        if wine.labelImage != imageData || (imageData != nil && wine.thumbnail == nil) {
            wine.labelImage = imageData
            wine.thumbnail = imageData.flatMap { ImageResizer.thumbnailData(from: $0) }
        }
    }
}
