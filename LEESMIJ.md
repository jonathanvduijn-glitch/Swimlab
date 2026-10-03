# Lees mij eerst: wat je nodig hebt

Gecontroleerd op 3 oktober 2026. Apple en Anthropic wijzigen eisen geregeld, dus check de links als je later begint.

## 1. Hardware en software

| Wat | Eis | Kosten |
|---|---|---|
| Mac | **Apple silicon** (M1 of nieuwer). Xcode 27 draait niet meer op Intel-Macs. | – |
| macOS | **Tahoe 26.6 of nieuwer** (Xcode 27-eis). Claude Code zelf vraagt macOS 13+. | gratis |
| Xcode | **Xcode 27** (sinds 14 sept. 2026) via de Mac App Store. Na installatie één keer openen en de iOS-simulator laten downloaden. | gratis |
| iPhone | Voor testen op je eigen toestel. Xcode 27 debugt op iOS 17 en nieuwer. | – |
| Claude Code | Betaald Claude-abonnement (Pro of Max). Het gratis plan heeft geen Claude Code. | abonnement |
| Apple Developer Program | Nodig voor TestFlight en de App Store. Zonder lidmaatschap kun je wel op je eigen iPhone testen, maar dan moet je de app elke 7 dagen opnieuw installeren. | **€ 99 per jaar** |

Controle: https://developer.apple.com/xcode/system-requirements/ en https://code.claude.com/docs/en/setup

## 2. Installeren (in deze volgorde)

1. **Xcode 27** uit de Mac App Store, openen, licentie accepteren, iOS-platform downloaden.
2. In Terminal: `xcode-select --install` (command line tools) en `xcodebuild -version` om te checken.
3. **Claude Code** (officiële installer, geen Node.js nodig):
   ```bash
   curl -fsSL https://claude.ai/install.sh | bash
   ```
   of `brew install --cask claude-code`. Daarna `claude` starten en inloggen. Eerder noemde ik `npm install -g`, dat is de oude methode.
4. **Git**: zit bij de command line tools. Maak een (privé) GitHub-repo als back-up.
5. **Node.js** alleen voor het data-extractiescript: `brew install node`.

## 3. Claude Code koppelen aan Xcode (aanrader)

Xcode heeft sinds 26.3 een ingebouwde MCP-server, zodat Claude Code kan bouwen, fouten lezen en SwiftUI-previews bekijken.

1. Xcode → Settings → Intelligence → zet **Xcode Tools** aan onder Model Context Protocol.
2. In Terminal:
   ```bash
   claude mcp add --transport stdio xcode -- xcrun mcpbridge
   ```
3. Xcode moet open staan met je project. Bij een nieuwe sessie vraagt Xcode om toestemming: klik “Allow”.

Werkt dit niet, dan bouwt Claude Code gewoon via `xcodebuild` in de terminal.

## 4. Project aanmaken (jij, in Xcode)

1. Xcode → File → New → Project → iOS → **App**.
2. Product Name: `Voedingswijzer`, Interface: **SwiftUI**, Language: **Swift**, Storage: **None** (Claude voegt SwiftData zelf toe), Testing System: **Swift Testing**, vink UI-tests aan.
3. Bundle Identifier bijvoorbeeld `nl.jouwnaam.voedingswijzer` (later niet meer te wijzigen in de App Store).
4. Zet de bestanden uit deze map in de **hoofdmap** van het project: `CLAUDE.md`, `PROMPTS.md`, `LEESMIJ.md` en de map `reference/`.
5. Open Terminal in die map, `git init` (als Xcode dat niet al deed), `claude`, en plak de prompt van Fase 0.

## 5. Keuzes die ik voor je heb gemaakt (en waarom)

- **Alleen lokale opslag, geen iCloud-sync.** Apple verbiedt het opslaan van persoonlijke gezondheidsinformatie in iCloud (Guideline 5.1.3(ii)). Voedingslogs vallen daar mogelijk onder; lokaal is veilig.
- **Geen account.** Zodra een app accounts aanbiedt, moet je ook verwijderen van het account in de app aanbieden (Guideline 5.1.1(v)) en heb je een server nodig. Voor v1 niet nodig.
- **Geen analytics of advertenties.** Dan kun je in App Store Connect “Data Not Collected” invullen en wordt je privacybeleid eenvoudig.
- **Supermarktprijzen blijven schattingen.** Er zijn geen openbare prijs-API's van Nederlandse supermarkten, en scrapen van hun sites kan in strijd zijn met hun voorwaarden.

## 6. Data en rechten

- **Voedingswaarden in het prototype** zijn afgeronde gemiddelden (NEVO/USDA-niveau) die ik heb samengesteld. Prima om mee te ontwikkelen; vervang ze voor een publieke release door officiële data.
- **NEVO (RIVM)**: gratis te downloaden na akkoord met de voorwaarden. Je mag de gegevens alleen ongewijzigd gebruiken, met bron en versienummer: “NEVO-online versie 2025/9.0, RIVM, Bilthoven”. Lees de voorwaarden voor commercieel gebruik: https://www.rivm.nl/documenten/voorwaarden-voor-gebruik-nevo-online
- **Open Food Facts** (barcodes, later): gratis en commercieel bruikbaar onder de ODbL. Voorwaarden: bronvermelding, share-alike voor afgeleide databases, en altijd een eigen User-Agent. Combineer je hun data met andere databases, dan moet die combinatie ook open zijn. Zie https://world.openfoodfacts.org/terms-of-use
- **Prijsindex**: de procentuele verschillen per supermarkt komen uit de prijspeiling van de Consumentenbond (peildatum 6 mei 2026). Vermeld de bron en werk ze bij als er een nieuwe peiling is.

## 7. App Store-checklist (als je wilt publiceren)

- [ ] Apple Developer Program-lidmaatschap (individu: je eigen naam staat als verkoper in de App Store).
- [ ] Gebouwd met **Xcode 26 of nieuwer en de iOS 26 SDK**, verplicht sinds 28 april 2026. Met Xcode 27 zit je goed.
- [ ] **Handelaarsstatus (DSA)** invullen in App Store Connect. Verplicht voor de EU. Als handelaar worden je adres en telefoonnummer openbaar getoond. Een gratis hobby-app zonder verdienmodel is vaak geen handelaar; twijfel je, vraag advies.
- [ ] **Privacybeleid-URL** (verplicht voor elke app). Een eenvoudige pagina volstaat, bijvoorbeeld via GitHub Pages.
- [ ] **App Privacy** (“privacylabel”) invullen in App Store Connect.
- [ ] `PrivacyInfo.xcprivacy` in de app (Claude maakt die in Fase 7).
- [ ] **Leeftijdsclassificatie**-vragenlijst invullen.
- [ ] Screenshots voor de vereiste iPhone-formaten.
- [ ] Geen medische claims in app of beschrijving. Een algemene voedings-/fitnessapp is normaal gesproken geen medisch hulpmiddel, maar dat verandert als je diagnoses of behandeladvies gaat geven.
- [ ] Gebruik je later Apple Gezondheid: noem in de beschrijving welke gezondheidsdata je gebruikt, schrijf alleen echte gegevens weg en gebruik ze nooit voor advertenties (Guideline 5.1.3).
- [ ] **Naam controleren**: zoek in de App Store en bij het Benelux-merkenregister (BOIP) of “Voedingswijzer” al in gebruik is.
- [ ] Eerst via **TestFlight** testen voordat je instuurt voor review.

Bronnen: https://developer.apple.com/news/upcoming-requirements/ · https://developer.apple.com/app-store/review/guidelines/ · https://developer.apple.com/programs/enroll/

## 8. Kosten in het kort

- Eenmalig: niets extra als je al een Apple silicon-Mac en iPhone hebt.
- Doorlopend: € 99 per jaar (Apple) plus je Claude-abonnement.
- Optioneel: domeinnaam voor je privacybeleid.

## 9. Handige gewoontes met Claude Code

- Eén fase per sessie, `/clear` tussen fases.
- Laat grote stappen eerst in plan mode uitwerken.
- Commit na elke fase; kan iets mis, dan ga je terug met git.
- Vraag Claude na elke fase: “Bouw, draai alle tests en maak een screenshot van de simulator.”
- Bewaar `CLAUDE.md` als levend document: als je een regel verandert, zet het daar.
