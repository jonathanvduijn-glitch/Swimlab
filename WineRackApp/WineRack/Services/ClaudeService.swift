import Foundation

// Instellingen voor de Claude-API.
enum ClaudeConfig {
    /// Het model dat de etiketten leest. Wil je een ander model? Pas dan alleen deze regel aan.
    static let model = "claude-sonnet-5-5"

    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let apiVersion = "2023-06-01"

    // Ruim genoeg voor het nadenken van het model plus het JSON-antwoord.
    static let maxTokens = 16000
}

// Foutmeldingen in gewone taal (altijd Nederlands).
enum ClaudeError: LocalizedError {
    case missingKey
    case invalidKey
    case unreadableLabel
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

// Stuurt een foto van het etiket naar Claude en krijgt de wijngegevens terug.
enum ClaudeService {
    static func scanLabel(jpegData: Data) async throws -> LabelScanResult {
        guard let apiKey = KeychainService.loadAPIKey() else { throw ClaudeError.missingKey }
        let year = DrinkStatus.currentYear

        var request = URLRequest(url: ClaudeConfig.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(ClaudeConfig.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody(jpegData: jpegData, year: year))

        // Versturen.
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
        switch status {
        case 200: break
        case 401: throw ClaudeError.invalidKey
        case 429: throw ClaudeError.tooManyRequests
        case 529: throw ClaudeError.overloaded
        default: throw ClaudeError.server(status: status)
        }

        // Afgebroken of geweigerd antwoord telt als "niet leesbaar".
        guard let message = try? JSONDecoder().decode(MessagesResponse.self, from: data),
              message.stopReason != "max_tokens",
              message.stopReason != "refusal" else {
            throw ClaudeError.unreadableLabel
        }

        // De tekst uit het antwoord als JSON inlezen.
        let text = message.content.compactMap(\.text).joined()
        guard var scan = LabelScanResult.parse(from: text), scan.isUsable else {
            throw ClaudeError.unreadableLabel
        }
        // Geen wijnnaam gevonden? Dan de producent als naam voorstellen.
        if scan.name.isEmpty {
            scan.name = scan.producer
        }
        return scan
    }

    private static func requestBody(jpegData: Data, year: Int) -> [String: Any] {
        [
            "model": ClaudeConfig.model,
            "max_tokens": ClaudeConfig.maxTokens,
            "system": systemPrompt(year: year),
            "output_config": [
                // Een etiket lezen is eenvoudig werk: weinig nadenken is genoeg.
                "effort": "low",
                // Dwingt een antwoord af dat precies aan dit JSON-schema voldoet.
                "format": [
                    "type": "json_schema",
                    "schema": labelSchema
                ]
            ],
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": jpegData.base64EncodedString()
                            ]
                        ],
                        [
                            "type": "text",
                            "text": "Lees dit wijnetiket. Het huidige jaar is \(year)."
                        ]
                    ]
                ]
            ]
        ]
    }

    // Het JSON-schema van het antwoord.
    private static var labelSchema: [String: Any] {
        let text: [String: Any] = ["type": "string"]
        let year: [String: Any] = ["anyOf": [["type": "integer"], ["type": "null"]]]
        return [
            "type": "object",
            "properties": [
                "readable": ["type": "boolean"],
                "name": text,
                "producer": text,
                "vintage": year,
                "grape": text,
                "region": text,
                "country": text,
                "type": ["type": "string", "enum": WineType.allCases.map(\.rawValue)],
                "drinkFrom": year,
                "drinkBy": year,
                "pairings": ["type": "array", "items": text],
                "notes": text
            ],
            "required": ["readable", "name", "producer", "vintage", "grape", "region", "country",
                         "type", "drinkFrom", "drinkBy", "pairings", "notes"],
            "additionalProperties": false
        ]
    }

    private static func systemPrompt(year: Int) -> String {
        """
        Je bent een ervaren sommelier. Je krijgt een foto van een wijnetiket. Het huidige jaar is \(year).
        Antwoord alleen met JSON volgens het opgegeven schema.

        Regels:
        - readable: false als het geen wijnetiket is of als je het niet kunt lezen; anders true.
        - name: de naam van de wijn (zonder jaargang).
        - vintage: de jaargang, of null als die er niet op staat.
        - country: het land in het Nederlands (bijv. Frankrijk, Italië, Spanje, Duitsland).
        - type: precies één van: Rood, Wit, Rosé, Mousserend, Dessert, Versterkt, Overig.
        - drinkFrom en drinkBy: jaartallen waarin de wijn op zijn best is. Schat ze op basis van stijl, regio, kwaliteit en jaargang, met \(year) als huidig jaar.
        - pairings: 4 tot 6 passende gerechten, in het Nederlands.
        - notes: 1 tot 2 zinnen over de smaak, in het Nederlands.
        - Onbekende tekst: lege string. Onbekend jaartal: null.
        """
    }

    // Alleen het deel van het API-antwoord dat we nodig hebben.
    private struct MessagesResponse: Decodable {
        struct Block: Decodable {
            let type: String
            let text: String?
        }
        let content: [Block]
        let stopReason: String?

        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
        }
    }
}
