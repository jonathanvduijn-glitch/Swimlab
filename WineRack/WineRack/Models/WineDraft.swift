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

    var hasName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        wine.labelImage = imageData
    }
}
