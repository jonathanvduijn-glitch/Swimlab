import Foundation
import SwiftData

// Voorbeeldwijnen voor de #Preview-blokken (alleen in het geheugen, niet bewaard).
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Wine.self, Tasting.self, configurations: configuration)
        let year = DrinkStatus.currentYear
        let context = container.mainContext

        let wines = [
            Wine(name: "Barolo", producer: "Giacomo Conterno", vintage: year - 10, grape: "Nebbiolo",
                 region: "Piemonte", country: "Italië", type: .red, location: .cellar, quantity: 3,
                 drinkFrom: year - 2, drinkBy: year + 8, pairings: ["Stoofvlees", "Truffelrisotto", "Wild"],
                 notes: "Roos, teer en kersen; stevige tannines.", rating: 5),
            Wine(name: "Sancerre", producer: "Domaine Vacheron", vintage: year - 3, grape: "Sauvignon Blanc",
                 region: "Loire", country: "Frankrijk", type: .white, location: .fridge, quantity: 2,
                 drinkFrom: year - 2, drinkBy: year, pairings: ["Geitenkaas", "Oesters"], rating: 4),
            Wine(name: "Rioja Reserva", producer: "La Rioja Alta", vintage: year - 12, grape: "Tempranillo",
                 region: "Rioja", country: "Spanje", type: .red, location: .cabinet, quantity: 1,
                 drinkFrom: year - 6, drinkBy: year - 1, pairings: ["Lamsrack"]),
            Wine(name: "Champagne Brut", producer: "Bollinger", grape: "Pinot Noir, Chardonnay",
                 region: "Champagne", country: "Frankrijk", type: .sparkling, location: .fridge, quantity: 0),
            Wine(name: "Riesling Spätlese", producer: "Egon Müller", vintage: year - 2, grape: "Riesling",
                 region: "Mosel", country: "Duitsland", type: .white, location: .cellar, quantity: 6,
                 drinkFrom: year + 3, drinkBy: year + 20),
            Wine(name: "Huiswijn", type: .rose, location: .cabinet, quantity: 4)
        ]
        wines.forEach { context.insert($0) }

        let tasting = Tasting(date: .now, dish: "Stoofvlees", note: "Heerlijk bij de kerst.")
        context.insert(tasting)
        tasting.wine = wines[0]
        return container
    }()

    // Eén voorbeeldwijn voor het detailscherm.
    static var sampleWine: Wine {
        let descriptor = FetchDescriptor<Wine>(sortBy: [SortDescriptor(\.name)])
        return try! container.mainContext.fetch(descriptor).first!
    }
}
