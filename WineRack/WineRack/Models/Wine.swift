import Foundation
import SwiftData

// Eén wijn in de voorraad.
// Elke property heeft een standaardwaarde en de relatie is optioneel,
// zodat iCloud-sync later kan worden aangezet.
@Model
final class Wine {
    var name: String = ""
    var producer: String = ""
    var vintage: Int? = nil
    var grape: String = ""
    var region: String = ""
    var country: String = ""
    var typeRaw: String = "Rood"
    var locationRaw: String = "Kelder"
    var quantity: Int = 1
    var drinkFrom: Int? = nil
    var drinkBy: Int? = nil
    var pairings: [String] = []
    var notes: String = ""
    var rating: Int = 0
    @Attribute(.externalStorage) var labelImage: Data? = nil
    var dateAdded: Date = Date.now

    // Gedronken flessen; worden mee verwijderd als de wijn wordt verwijderd.
    @Relationship(deleteRule: .cascade, inverse: \Tasting.wine)
    var tastings: [Tasting]? = []

    init(
        name: String = "",
        producer: String = "",
        vintage: Int? = nil,
        grape: String = "",
        region: String = "",
        country: String = "",
        type: WineType = .red,
        location: WineLocation = .cellar,
        quantity: Int = 1,
        drinkFrom: Int? = nil,
        drinkBy: Int? = nil,
        pairings: [String] = [],
        notes: String = "",
        rating: Int = 0
    ) {
        self.name = name
        self.producer = producer
        self.vintage = vintage
        self.grape = grape
        self.region = region
        self.country = country
        self.typeRaw = type.rawValue
        self.locationRaw = location.rawValue
        self.quantity = quantity
        self.drinkFrom = drinkFrom
        self.drinkBy = drinkBy
        self.pairings = pairings
        self.notes = notes
        self.rating = rating
        self.dateAdded = .now
    }
}

extension Wine {
    // Type als enum; opgeslagen als tekst in typeRaw.
    var type: WineType {
        get { WineType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    // Locatie als enum; opgeslagen als tekst in locationRaw.
    var location: WineLocation {
        get { WineLocation(rawValue: locationRaw) ?? .cellar }
        set { locationRaw = newValue.rawValue }
    }

    var drinkStatus: DrinkStatus {
        DrinkStatus(drinkFrom: drinkFrom, drinkBy: drinkBy)
    }

    // Naam met jaargang, bijv. "Barolo 2016".
    var displayName: String {
        guard let vintage else { return name }
        return "\(name) \(vintage)"
    }

    // Drinkperiode als tekst, bijv. "2024 – 2030" of "vóór 2030".
    var drinkWindowText: String? {
        switch (drinkFrom, drinkBy) {
        case let (from?, by?): "\(from) – \(by)"
        case let (from?, nil): "vanaf \(from)"
        case let (nil, by?): "vóór \(by)"
        case (nil, nil): nil
        }
    }
}
