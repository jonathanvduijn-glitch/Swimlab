import Foundation

// Instellingen voor de Claude-API.
enum ClaudeConfig {
    /// Het model dat de etiketten leest. Wil je een ander model? Pas dan alleen deze regel aan.
    static let model = "claude-sonnet-5-5"

    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let apiVersion = "2023-06-01"
}

// Foutmeldingen in gewone taal.
enum ClaudeError: LocalizedError {
    case missingKey
    case invalidKey
    case unreadableLabel
    case network(String)
    case server(status: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .missingKey:
            "Er is nog geen Claude API-sleutel ingevuld. Tik op het tandwiel om je sleutel te bewaren."
        case .invalidKey:
            "De API-sleutel is ongeldig (fout 401). Controleer je sleutel bij het tandwiel."
        case .unreadableLabel:
            "Claude kon het etiket niet lezen. Probeer een scherpere foto, of vul de wijn zelf in."
        case .network(let detail):
            "Er is geen verbinding met Claude gelukt. Controleer je internet en probeer het opnieuw. (\(detail))"
        case .server(let status, let message):
            "Er ging iets mis bij Claude (fout \(status)). \(message ?? "Probeer het later opnieuw.")"
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
        request.timeoutInterval = 90
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(ClaudeConfig.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody(jpegData: jpegData, year: year))

        // Versturen.
        let result: (Data, URLResponse)
        do {
            result = try await URLSession.shared.data(for: request)
        } catch {
            throw ClaudeError.network(error.localizedDescription)
        }
        let (data, response) = result

        // Antwoord controleren.
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 { throw ClaudeError.invalidKey }
        guard status == 200 else {
            throw ClaudeError.server(status: status, message: apiErrorMessage(from: data))
        }

        // De tekst uit het antwoord halen en als JSON inlezen.
        let message = try? JSONDecoder().decode(MessagesResponse.self, from: data)
        let text = message?.content.compactMap(\.text).joined() ?? ""
        guard let scan = LabelScanResult.parse(from: text), !scan.name.isEmpty else {
            throw ClaudeError.unreadableLabel
        }
        return scan
    }

    private static func requestBody(jpegData: Data, year: Int) -> [String: Any] {
        [
            "model": ClaudeConfig.model,
            "max_tokens": 1024,
            "system": systemPrompt(year: year),
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
                            "text": "Lees dit wijnetiket. Het huidige jaar is \(year). Antwoord alleen met JSON."
                        ]
                    ]
                ]
            ]
        ]
    }

    private static func systemPrompt(year: Int) -> String {
        """
        Je bent een ervaren sommelier. Je krijgt een foto van een wijnetiket. Het huidige jaar is \(year).
        Antwoord ALLEEN met één JSON-object, zonder uitleg en zonder markdown, precies in deze vorm:
        {"name": "", "producer": "", "vintage": 2019, "grape": "", "region": "", "country": "", "type": "", "drinkFrom": 2024, "drinkBy": 2030, "pairings": [""], "notes": ""}

        Regels:
        - name: de naam van de wijn (zonder jaargang).
        - vintage: de jaargang als getal, of null als die er niet op staat.
        - country: het land in het Nederlands (bijv. Frankrijk, Italië, Spanje, Duitsland).
        - type: precies één van: Rood, Wit, Rosé, Mousserend, Dessert, Versterkt, Overig.
        - drinkFrom en drinkBy: jaartallen waarin de wijn op zijn best is. Schat ze op basis van stijl, regio, kwaliteit en jaargang, met \(year) als huidig jaar.
        - pairings: 4 tot 6 passende gerechten, in het Nederlands.
        - notes: 1 tot 2 zinnen over de smaak, in het Nederlands.
        - Onbekende tekst: lege string. Onbekend jaartal: null.
        - Kun je het etiket niet lezen, antwoord dan: {"error": "onleesbaar"}
        """
    }

    // Haalt de foutmelding uit een foutantwoord van de API (als die er is).
    private static func apiErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any] else { return nil }
        return error["message"] as? String
    }

    // Alleen het deel van het API-antwoord dat we nodig hebben.
    private struct MessagesResponse: Decodable {
        struct Block: Decodable {
            let type: String
            let text: String?
        }
        let content: [Block]
    }
}
