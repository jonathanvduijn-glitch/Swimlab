import Foundation

// Wat Claude van het etiket heeft gelezen.
// Het inlezen is bewust vergevingsgezind: jaartallen mogen een getal of tekst zijn,
// en ontbrekende velden worden leeg.
struct LabelScanResult: Decodable {
    var readable = true
    var name = ""
    var producer = ""
    var vintage: Int?
    var grape = ""
    var region = ""
    var country = ""
    var type = ""
    var drinkFrom: Int?
    var drinkBy: Int?
    var pairings: [String] = []
    var notes = ""

    private enum CodingKeys: String, CodingKey {
        case readable, name, producer, vintage, grape, region, country, type, drinkFrom, drinkBy, pairings, notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        readable = (try? container.decodeIfPresent(Bool.self, forKey: .readable)) ?? true
        name = Self.text(container, .name)
        producer = Self.text(container, .producer)
        vintage = Self.year(container, .vintage)
        grape = Self.text(container, .grape)
        region = Self.text(container, .region)
        country = Self.text(container, .country)
        type = Self.text(container, .type)
        drinkFrom = Self.year(container, .drinkFrom)
        drinkBy = Self.year(container, .drinkBy)
        notes = Self.text(container, .notes)
        // Gerechten opschonen: geen lege en geen dubbele.
        let list = (try? container.decodeIfPresent([String].self, forKey: .pairings)) ?? []
        for dish in list.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        where !dish.isEmpty && !pairings.contains(dish) {
            pairings.append(dish)
        }
    }

    // Bruikbaar als Claude het etiket kon lezen en er een naam of producent op stond.
    var isUsable: Bool {
        readable && !(name.isEmpty && producer.isEmpty)
    }

    // Zoekt de eerste { en de laatste } in het antwoord en leest de JSON daartussen.
    static func parse(from text: String) -> LabelScanResult? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        let json = String(text[start...end])
        return try? JSONDecoder().decode(LabelScanResult.self, from: Data(json.utf8))
    }

    private static func text(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String {
        let value = (try? container.decodeIfPresent(String.self, forKey: key)) ?? ""
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Accepteert 2030, 2030.0 en "2030" (of "ca. 2030").
    private static func year(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Int? {
        if let number = try? container.decodeIfPresent(Int.self, forKey: key) {
            return validYear(number)
        }
        if let number = try? container.decodeIfPresent(Double.self, forKey: key) {
            return validYear(Int(number))
        }
        if let string = try? container.decodeIfPresent(String.self, forKey: key),
           let range = string.range(of: "\\d{4}", options: .regularExpression) {
            return validYear(Int(string[range]))
        }
        return nil
    }

    private static func validYear(_ year: Int?) -> Int? {
        guard let year, WineDraft.validYears.contains(year) else { return nil }
        return year
    }
}

// Antwoord bij zoeken op naam: een lijst wijnen.
struct WineSearchResponse: Decodable {
    var wines: [LabelScanResult] = []

    static func parse(from text: String) -> WineSearchResponse? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start < end else { return nil }
        let json = String(text[start...end])
        return try? JSONDecoder().decode(WineSearchResponse.self, from: Data(json.utf8))
    }
}

extension WineDraft {
    // Vult het formulier met wat Claude heeft gelezen.
    mutating func fill(from result: LabelScanResult) {
        name = result.name
        producer = result.producer
        vintage = result.vintage
        grape = result.grape
        region = result.region
        country = result.country
        type = WineType.from(result.type) ?? .other
        drinkFrom = result.drinkFrom
        drinkBy = result.drinkBy
        pairings = result.pairings
        notes = result.notes
    }
}
