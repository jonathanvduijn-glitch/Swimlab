import Foundation
import SwiftData

// Een gedronken fles: wanneer, bij welk gerecht en hoe hij was.
@Model
final class Tasting {
    var date: Date = Date.now
    var dish: String = ""
    var note: String = ""
    var wine: Wine? = nil

    init(date: Date = .now, dish: String = "", note: String = "") {
        self.date = date
        self.dish = dish
        self.note = note
    }
}
