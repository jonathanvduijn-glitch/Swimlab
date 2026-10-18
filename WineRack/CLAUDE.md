# Wine Rack

Persoonlijke iPhone-app om een wijnvoorraad bij te houden. De eigenaar is geen
programmeur: praat Nederlands, in gewone taal. Alle tekst in de app is Nederlands.

## Wat de app doet

- Wijnen toevoegen door een foto van het etiket te maken of te kiezen. Claude
  (Anthropic API) leest het etiket en vult het formulier vooraf in; de gebruiker
  controleert alles en bewaart.
- Hoofdlijst "Wine Rack", gegroepeerd op drinkstatus (meest urgent bovenaan,
  binnen een groep gesorteerd op "drinken vóór"), aparte sectie "Op" voor wijnen
  met 0 flessen, filter Alles/Koeling/Kast/Kelder, totaal aantal flessen en
  zoeken op naam, producent, druif, regio en gerecht.
- Vegen in de lijst: naar rechts = "Gedronken", naar links = "Verwijder".
- Detailscherm met etiketfoto, drinkstatus, aantal en locatie (direct
  opgeslagen), sterren, "Past bij", notities en geschiedenis van gedronken flessen.
- "Fles gedronken": datum, gerecht (snelkeuze uit de gerechten van de wijn),
  notitie. Slaat een Tasting op en verlaagt het aantal met 1 (niet onder 0).
- Instellingen: Claude API-sleutel invullen (alleen in de Keychain), model tonen.

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
  bestanden in de map `WineRack/WineRack/` horen automatisch bij de app.
- Swift 5-taalmodus, Default Actor Isolation = nonisolated.
- SwiftData-regels (voor iCloud-sync later): elke property heeft een
  standaardwaarde, relaties zijn optioneel, enums worden als String opgeslagen
  (`typeRaw`, `locationRaw`) met een berekende property (`type`, `location`).
- Claude-API: `POST https://api.anthropic.com/v1/messages`, headers `x-api-key`,
  `anthropic-version: 2023-06-01`, `content-type: application/json`. Het model staat
  in één constante: `ClaudeConfig.model` in `Services/ClaudeService.swift`
  (nu `claude-sonnet-5-5`).
- Foto's: max. 1568 px naar de API, max. 1024 px bewaard (JPEG, externalStorage).
- De API-sleutel staat ALLEEN in de Keychain. Nooit in code, logs of UserDefaults.
- Camera-toestemming: NSCameraUsageDescription staat in de build settings
  (`INFOPLIST_KEY_NSCameraUsageDescription`).

## Mapstructuur

```
WineRack/
├── CLAUDE.md
├── WineRack.xcodeproj
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
    │   ├── ClaudeService.swift  etiket laten lezen door Claude
    │   ├── LabelScanResult.swift  robuust JSON-antwoord inlezen
    │   ├── KeychainService.swift  API-sleutel veilig bewaren
    │   └── ImageResizer.swift   foto's verkleinen
    └── Views/
        ├── WineListView.swift   hoofdlijst
        ├── WineRowView.swift    één rij + miniatuur
        ├── AddWineView.swift    foto kiezen/maken en scannen
        ├── CameraPicker.swift   camera
        ├── WineFormView.swift   formulier (toevoegen en wijzigen)
        ├── WineDetailView.swift detailscherm
        ├── TastingSheet.swift   "Fles gedronken"
        ├── SettingsView.swift   instellingen
        └── StarRatingView.swift sterren
```

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
