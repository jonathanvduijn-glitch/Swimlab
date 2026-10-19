# Wine Rack

Persoonlijke iPhone-app om een wijnvoorraad bij te houden. De eigenaar is geen
programmeur: praat Nederlands, in gewone taal. Alle tekst in de app is Nederlands.

## Wat de app doet

- Wijnen toevoegen door een foto van het etiket te maken of te kiezen. Claude
  (Anthropic API) leest het etiket en vult het formulier vooraf in; de gebruiker
  controleert alles en bewaart.
- Of: wijn zoeken op naam ("Zoek op naam" bij +). Eerst snel uit Claude's eigen
  kennis; met de knop "Zoek op internet" zoekt Claude live op het web (server-tool
  `web_search_20260209`, max. 5 zoekopdrachten, een paar cent per keer). Maximaal 5
  treffers; een tik vult het formulier.
- Aroma's: losse geuren/smaken per wijn (`Wine.aromas`), door Claude ingevuld, zelf
  aan te passen, als labeltjes op het detailscherm en doorzoekbaar in de lijst.
- Hoofdlijst "Wine Rack", gegroepeerd op drinkstatus (meest urgent bovenaan,
  binnen een groep gesorteerd op "drinken vóór"), aparte sectie "Op" voor wijnen
  met 0 flessen, filter Alles/Koeling/Kast/Kelder, totaal aantal flessen en
  zoeken op naam, producent, druif, regio en gerecht.
- Vegen in de lijst: naar rechts = "Gedronken", naar links = "Verwijder".
- Detailscherm met etiketfoto, drinkstatus, aantal en locatie (direct
  opgeslagen), sterren, "Past bij", notities en geschiedenis van gedronken flessen.
- "Fles gedronken": datum, gerecht (snelkeuze uit de gerechten van de wijn),
  notitie. Slaat een Tasting op en verlaagt het aantal met 1 (niet onder 0).
- Instellingen: Claude API-sleutel invullen (alleen in de Keychain), knop "Test
  verbinding" (klein testverzoek: werkt de sleutel, is er tegoed?), model tonen.

### Drinkstatus (berekend uit het huidige jaar)

| Status | Regel | Kleur |
| --- | --- | --- |
| Over zijn hoogtepunt | drinkBy < dit jaar | rood |
| Dit jaar opdrinken | drinkBy == dit jaar | oranje |
| Op dronk | anders, als er een periode bekend is | groen |
| Nog laten liggen | drinkFrom > dit jaar | blauw |
| Onbekend | geen drinkFrom en geen drinkBy | grijs |

## Techniek

- SwiftUI + SwiftData, minimaal iOS 17.0, alleen Apple-frameworks (geen packages).
- Draait op iPhone, in de simulator en op "My Mac (Designed for iPhone)".
- Xcode-project met een "synchronized folder" (Xcode 16 of nieuwer): nieuwe
  bestanden in de map `WineRackApp/WineRack/` horen automatisch bij de app.
- Swift 5-taalmodus, Default Actor Isolation = nonisolated.
- SwiftData-regels (voor iCloud-sync later): elke property heeft een
  standaardwaarde, relaties zijn optioneel, enums worden als String opgeslagen
  (`typeRaw`, `locationRaw`) met een berekende property (`type`, `location`).
- Claude-API: `POST https://api.anthropic.com/v1/messages`, headers `x-api-key`,
  `anthropic-version: 2023-06-01`, `content-type: application/json`. Het model staat
  in één constante: `ClaudeConfig.model` in `Services/ClaudeService.swift`
  (nu `claude-sonnet-5-5`).
- Het verzoek gebruikt `output_config.format` (JSON-schema) zodat het antwoord altijd
  geldige JSON is, `effort: "low"` en `max_tokens: 16000` (het model denkt standaard
  eerst na en dat telt mee). `stop_reason` "max_tokens" of "refusal" geeft de melding
  "etiket onleesbaar". Zoeken op internet gebruikt geen `output_config.format`
  (combinatie met web search niet gedocumenteerd): JSON via de prompt, en als dat
  niet te lezen is een tweede verzoek mét schema dat de tekst omzet. `pause_turn`
  wordt maximaal 3 keer hervat.
- Foutafhandeling (`ClaudeService.mapError`): de Engelse foutmelding van de API wordt
  alleen gebruikt om de oorzaak te herkennen ("credit balance" = geen tegoed, "web
  search" = zoeken op internet staat uit) en nooit getoond. Alle meldingen in de app
  zijn Nederlands.
- Foto's: max. 1568 px naar de API, max. 1024 px bewaard (JPEG, externalStorage),
  plus een miniatuur van 160 px (`Wine.thumbnail`) voor de lijst. Verkleinen gebeurt
  buiten de hoofdthread.
- Jaartallen in het formulier moeten tussen 1800 en 2200 liggen en "vanaf" mag niet
  na "vóór" liggen; anders is "Bewaar" uitgeschakeld.
- De API-sleutel staat ALLEEN in de Keychain. Nooit in code, logs of UserDefaults.
- Camera-toestemming: NSCameraUsageDescription staat in de build settings
  (`INFOPLIST_KEY_NSCameraUsageDescription`).

## Mapstructuur

```
WineRackApp/
├── CLAUDE.md
├── WineRackApp.xcodeproj    dit bestand openen in Xcode
└── WineRack/
    ├── WineRackApp.swift        start van de app, SwiftData-container
    ├── Assets.xcassets          app-icoon en accentkleur
    ├── Models/
    │   ├── Wine.swift           wijn (SwiftData)
    │   ├── Tasting.swift        gedronken fles (SwiftData)
    │   ├── WineType.swift       Rood/Wit/Rosé/…
    │   ├── WineLocation.swift   Koeling/Kast/Kelder + lijstfilter
    │   ├── DrinkStatus.swift    drinkstatus + kleuren
    │   ├── WineDraft.swift      tijdelijke kopie voor het formulier
    │   └── PreviewData.swift    voorbeeldwijnen voor #Preview
    ├── Services/
    │   ├── ClaudeService.swift  etiket lezen en wijnen zoeken via Claude
    │   ├── LabelScanResult.swift  robuust JSON-antwoord inlezen
    │   ├── KeychainService.swift  API-sleutel veilig bewaren
    │   └── ImageResizer.swift   foto's verkleinen
    └── Views/
        ├── WineListView.swift   hoofdlijst
        ├── WineRowView.swift    één rij + miniatuur
        ├── AddWineView.swift    foto kiezen/maken en scannen
        ├── WineSearchView.swift zoeken op naam
        ├── CameraPicker.swift   camera
        ├── WineFormView.swift   formulier (toevoegen en wijzigen)
        ├── WineDetailView.swift detailscherm
        ├── TastingSheet.swift   "Fles gedronken"
        ├── SettingsView.swift   instellingen
        └── StarRatingView.swift sterren
```

## Openen en bouwen

- Het project staat in de repository in de map `WineRackApp/` (eigen naam, zodat het
  niet botst met een ouder leeg project "WineRack" op de Mac). Openen in Xcode:
  `WineRackApp/WineRackApp.xcodeproj`. De app heet op het scherm gewoon "Wine Rack".
- GitHub bouwt de app automatisch bij elke wijziging in `WineRackApp/`
  (`.github/workflows/winerack-build.yml`, macOS-runner, nieuwste Xcode) en faalt
  bij waarschuwingen of fouten in de eigen code.

## Werkwijze

- Views kort en overzichtelijk, met Nederlandse commentaarregels.
- #Preview-blokken met een in-memory container (`PreviewData`).
- Na elke wijziging bouwen; fouten en waarschuwingen oplossen. Geen
  `@preconcurrency` of `nonisolated(unsafe)` als oplossing.
- Dit bestand bijwerken als er iets verandert.

## Plannen voor later (nog niet gebouwd)

1. Meldingen in januari en aan het begin van elke maand met de wijnen die dit
   jaar op moeten.
2. "Wat drink ik vanavond?": gerecht invoeren en passende wijnen uit eigen
   voorraad zien.
3. Widget op het beginscherm.
4. iCloud-sync.
5. Statistieken.
6. Kassabon scannen voor meerdere flessen.
7. App-icoon en kleuren in wijnrood.
