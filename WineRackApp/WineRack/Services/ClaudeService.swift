import Foundation

// Instellingen voor de Claude-API.
enum ClaudeConfig {
    /// Het model dat de etiketten leest en wijnen zoekt. Wil je een ander model? Pas dan alleen deze regel aan.
    static let model = "claude-sonnet-5-5"

    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let apiVersion = "2023-06-01"

    // Ruim genoeg voor het nadenken van het model plus het JSON-antwoord.
    static let maxTokens = 16000

    // Maximaal aantal internetzoekopdrachten per keer zoeken (houdt de kosten laag).
    static let maxWebSearches = 5
}

// Foutmeldingen in gewone taal (altijd Nederlands).
enum ClaudeError: LocalizedError {
    case missingKey
    case invalidKey
    case unreadableLabel
    case noResults
    case webSearchUnavailable
    case noConnection
    case timedOut
    case otherNetwork
    case tooManyRequests
    case overloaded
    case server(status: Int)

    var errorDescription: String? {
        switch self {
        case .missingKey:
            "Er is nog geen Claude API-sleutel ingevuld. Tik op het tandwiel om je sleutel te bewaren."
        case .invalidKey:
            "De API-sleutel is ongeldig (fout 401). Controleer je sleutel bij het tandwiel."
        case .unreadableLabel:
            "Claude kon het etiket niet lezen. Probeer een scherpere foto, of vul de wijn zelf in."
        case .noResults:
            "Claude vond geen wijn met deze naam. Probeer een andere schrijfwijze of voeg de producent of jaargang toe."
        case .webSearchUnavailable:
            "Zoeken op internet lukte niet. Controleer in de Claude Console of zoeken op internet aanstaat voor je account."
        case .noConnection:
            "Er is geen internetverbinding. Controleer je verbinding en probeer het opnieuw."
        case .timedOut:
            "Claude deed er te lang over. Probeer het opnieuw."
        case .otherNetwork:
            "Er is geen verbinding met Claude gelukt. Probeer het opnieuw."
        case .tooManyRequests:
            "Er zijn te veel verzoeken achter elkaar gedaan (fout 429). Wacht even en probeer het opnieuw."
        case .overloaded:
            "Claude is op dit moment erg druk. Probeer het over een paar minuten opnieuw."
        case .server(let status):
            "Er ging iets mis bij Claude (fout \(status)). Probeer het later opnieuw."
        }
    }
}

// Vraagt Claude om wijngegevens: via een foto van het etiket of via een zoekterm.
enum ClaudeService {
    // Foto van het etiket laten lezen.
    static func scanLabel(jpegData: Data) async throws -> LabelScanResult {
        let year = DrinkStatus.currentYear
        let content: [[String: Any]] = [
            [
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": jpegData.base64EncodedString()
                ]
            ],
            ["type": "text", "text": "Lees dit wijnetiket. Het huidige jaar is \(year)."]
        ]

        // Afgebroken, geweigerd of onleesbaar antwoord telt als "niet leesbaar".
        guard let text = try await sendJSON(system: labelPrompt(year: year), content: content, schema: labelSchema),
              var scan = LabelScanResult.parse(from: text),
              scan.isUsable else {
            throw ClaudeError.unreadableLabel
        }
        // Geen wijnnaam gevonden? Dan de producent als naam voorstellen.
        if scan.name.isEmpty {
            scan.name = scan.producer
        }
        return scan
    }

    // Wijnen zoeken op naam (maximaal 5 treffers).
    // Zonder internet: snel, uit Claude's eigen kennis. Met internet: Claude zoekt live op het web.
    static func searchWines(query: String, onInternet: Bool) async throws -> [LabelScanResult] {
        let text: String?
        if onInternet {
            text = try await searchOnInternet(query: query)
        } else {
            text = try await sendJSON(system: searchPrompt(year: DrinkStatus.currentYear),
                                      content: [["type": "text", "text": "Zoek deze wijn: \(query)"]],
                                      schema: searchSchema)
        }

        guard let text, let response = WineSearchResponse.parse(from: text) else {
            throw ClaudeError.noResults
        }
        let wines = response.wines
            .filter(\.isUsable)
            .map { found -> LabelScanResult in
                var wine = found
                if wine.name.isEmpty { wine.name = wine.producer }
                return wine
            }
        guard !wines.isEmpty else { throw ClaudeError.noResults }
        return Array(wines.prefix(5))
    }

    // MARK: - Zoeken op internet

    // Laat Claude op internet zoeken en geeft de JSON-tekst terug.
    private static func searchOnInternet(query: String) async throws -> String? {
        let year = DrinkStatus.currentYear
        var messages: [[String: Any]] = [
            ["role": "user", "content": [["type": "text", "text": "Zoek deze wijn op internet: \(query)"]]]
        ]

        // Bij een lange zoektocht pauzeert de server soms ("pause_turn"); dan gaan we verder.
        var answer: String?
        for _ in 0..<3 {
            let reply = try await post(body: [
                "model": ClaudeConfig.model,
                "max_tokens": ClaudeConfig.maxTokens,
                "system": webSearchPrompt(year: year),
                "tools": [[
                    "type": "web_search_20260209",
                    "name": "web_search",
                    "max_uses": ClaudeConfig.maxWebSearches
                ]],
                "output_config": ["effort": "medium"],
                "messages": messages
            ], usesWebSearch: true)

            if reply.stopReason == "pause_turn" {
                messages.append(["role": "assistant", "content": reply.content])
                continue
            }
            if reply.stopReason != "max_tokens" && reply.stopReason != "refusal" {
                answer = reply.text
            }
            break
        }

        guard let answer, !answer.isEmpty else { return nil }
        if WineSearchResponse.parse(from: answer) != nil { return answer }

        // Antwoord niet netjes als JSON? Laat Claude de gevonden informatie omzetten (zonder opnieuw te zoeken).
        return try await sendJSON(
            system: searchPrompt(year: year),
            content: [["type": "text", "text": "Zet deze gevonden informatie over \"\(query)\" om naar het schema:\n\n\(answer)"]],
            schema: searchSchema
        )
    }

    // MARK: - Versturen

    // Antwoord van de API: waarom het stopte, de tekst en de ruwe inhoud.
    private struct Reply {
        let stopReason: String?
        let text: String
        let content: [[String: Any]]
    }

    // Verzoek met een verplicht JSON-schema. Geeft nil als het antwoord is afgebroken of geweigerd.
    private static func sendJSON(system: String, content: [[String: Any]], schema: [String: Any]) async throws -> String? {
        let reply = try await post(body: [
            "model": ClaudeConfig.model,
            "max_tokens": ClaudeConfig.maxTokens,
            "system": system,
            "output_config": [
                // Eenvoudig werk: weinig nadenken is genoeg (sneller en goedkoper).
                "effort": "low",
                // Dwingt een antwoord af dat precies aan het JSON-schema voldoet.
                "format": ["type": "json_schema", "schema": schema]
            ],
            "messages": [["role": "user", "content": content]]
        ], usesWebSearch: false)

        guard reply.stopReason != "max_tokens", reply.stopReason != "refusal" else { return nil }
        return reply.text
    }

    // Stuurt een verzoek naar de API en controleert het antwoord.
    private static func post(body: [String: Any], usesWebSearch: Bool) async throws -> Reply {
        guard let apiKey = KeychainService.loadAPIKey() else { throw ClaudeError.missingKey }

        var request = URLRequest(url: ClaudeConfig.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = usesWebSearch ? 180 : 120
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(ClaudeConfig.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let result: (Data, URLResponse)
        do {
            result = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                throw ClaudeError.noConnection
            case .timedOut:
                throw ClaudeError.timedOut
            default:
                throw ClaudeError.otherNetwork
            }
        } catch {
            throw ClaudeError.otherNetwork
        }
        let (data, response) = result

        // Statuscode controleren.
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if usesWebSearch && (status == 400 || status == 403) {
            throw ClaudeError.webSearchUnavailable
        }
        switch status {
        case 200: break
        case 401: throw ClaudeError.invalidKey
        case 429: throw ClaudeError.tooManyRequests
        case 529: throw ClaudeError.overloaded
        default: throw ClaudeError.server(status: status)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw ClaudeError.server(status: status)
        }
        let text = content
            .filter { $0["type"] as? String == "text" }
            .compactMap { $0["text"] as? String }
            .joined()
        return Reply(stopReason: json["stop_reason"] as? String, text: text, content: content)
    }

    // MARK: - Schema's

    // Velden van één wijn in het antwoord.
    private static var wineProperties: [String: Any] {
        let text: [String: Any] = ["type": "string"]
        let list: [String: Any] = ["type": "array", "items": text]
        let year: [String: Any] = ["anyOf": [["type": "integer"], ["type": "null"]]]
        return [
            "name": text,
            "producer": text,
            "vintage": year,
            "grape": text,
            "region": text,
            "country": text,
            "type": ["type": "string", "enum": WineType.allCases.map(\.rawValue)],
            "drinkFrom": year,
            "drinkBy": year,
            "pairings": list,
            "aromas": list,
            "notes": text
        ]
    }

    private static let wineFields = ["name", "producer", "vintage", "grape", "region", "country",
                                     "type", "drinkFrom", "drinkBy", "pairings", "aromas", "notes"]

    // Antwoord bij een etiketfoto: één wijn plus "leesbaar ja/nee".
    private static var labelSchema: [String: Any] {
        var properties = wineProperties
        properties["readable"] = ["type": "boolean"]
        return [
            "type": "object",
            "properties": properties,
            "required": ["readable"] + wineFields,
            "additionalProperties": false
        ]
    }

    // Antwoord bij zoeken: een lijst wijnen.
    private static var searchSchema: [String: Any] {
        let wine: [String: Any] = [
            "type": "object",
            "properties": wineProperties,
            "required": wineFields,
            "additionalProperties": false
        ]
        return [
            "type": "object",
            "properties": ["wines": ["type": "array", "items": wine]],
            "required": ["wines"],
            "additionalProperties": false
        ]
    }

    // MARK: - Prompts

    // Regels die voor elke wijn gelden.
    private static func wineRules(year: Int) -> String {
        """
        - name: de naam van de wijn (zonder jaargang).
        - vintage: de jaargang, of null als die onbekend is.
        - country: het land in het Nederlands (bijv. Frankrijk, Italië, Spanje, Duitsland).
        - type: precies één van: Rood, Wit, Rosé, Mousserend, Dessert, Versterkt, Overig.
        - drinkFrom en drinkBy: jaartallen waarin de wijn op zijn best is. Schat ze op basis van stijl, regio, kwaliteit en jaargang, met \(year) als huidig jaar.
        - pairings: 4 tot 6 passende gerechten, in het Nederlands.
        - aromas: 4 tot 8 losse geuren en smaken die je in de wijn terugvindt, in het Nederlands en met kleine letters (bijv. "kers", "pruim", "tabak", "vanille", "citrus").
        - notes: 1 tot 2 zinnen over de smaak, in het Nederlands.
        - Onbekende tekst: lege string. Onbekend jaartal: null.
        """
    }

    private static func labelPrompt(year: Int) -> String {
        """
        Je bent een ervaren sommelier. Je krijgt een foto van een wijnetiket. Het huidige jaar is \(year).
        Antwoord alleen met JSON volgens het opgegeven schema.

        Regels:
        - readable: false als het geen wijnetiket is of als je het niet kunt lezen; anders true.
        \(wineRules(year: year))
        """
    }

    private static func searchPrompt(year: Int) -> String {
        """
        Je bent een ervaren sommelier met grote kennis van wijnen en producenten. Je krijgt een zoekterm, bijvoorbeeld de naam van een wijn, een producent of een jaargang. Het huidige jaar is \(year).
        Geef de wijnen die het best bij de zoekterm passen: de beste treffer eerst, maximaal 5. Noem alleen wijnen die echt bestaan; verzin geen wijnen. Staat er een jaargang in de zoekterm, gebruik die dan. Ken je geen passende wijn, geef dan een lege lijst.
        Antwoord alleen met JSON volgens het opgegeven schema.

        Regels per wijn:
        \(wineRules(year: year))
        """
    }

    private static func webSearchPrompt(year: Int) -> String {
        """
        Je bent een ervaren sommelier. Je krijgt een zoekterm, bijvoorbeeld de naam van een wijn, een producent of een jaargang. Het huidige jaar is \(year).
        Zoek op internet naar de wijnen die het best bij de zoekterm passen. Gebruik bij voorkeur de website van de wijnmaker, wijnhandels en recensies. Neem geuren, smaken en gerechten over uit wat je vindt, aangevuld met je eigen kennis.
        Geef maximaal 5 wijnen, de beste treffer eerst. Noem alleen wijnen die echt bestaan. Vind je niets, geef dan een lege lijst.

        Je laatste bericht bevat ALLEEN één JSON-object, zonder uitleg en zonder markdown, in deze vorm:
        {"wines": [{"name": "", "producer": "", "vintage": null, "grape": "", "region": "", "country": "", "type": "Rood", "drinkFrom": null, "drinkBy": null, "pairings": [""], "aromas": [""], "notes": ""}]}

        Regels per wijn:
        \(wineRules(year: year))
        """
    }
}
