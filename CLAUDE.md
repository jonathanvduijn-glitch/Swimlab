# Voedingswijzer – iOS-app

Native iPhone-app om voeding, eiwit, vitamines/mineralen, supplementen en creatine te tracken, met een weekplan voor recompositie (spier op, vet af) en een slimme boodschappenlijst met prijsvergelijking per supermarkt. Alle teksten in de app zijn **Nederlands**. Code, bestandsnamen en commentaar in het **Engels**.

Er is een werkend webprototype: `reference/voedingswijzer-prototype.html`. Dat is de **functionele bron van waarheid**. Lees het voordat je iets bouwt. Neem gedrag, formules en data over; kopieer het visuele ontwerp niet letterlijk maar vertaal het naar native iOS (SwiftUI, systeemcomponenten, Dynamic Type, donkere modus).

## Techniek (vast)

- Xcode 27 (Swift 6.4), SwiftUI, iPhone. Deployment target **iOS 18.0**.
- Opslag: **SwiftData, alleen lokaal op het toestel**. Geen CloudKit/iCloud-sync van gezondheids- of voedingsdata (App Review Guideline 5.1.3(ii)).
- Geen accounts, geen login, geen eigen backend in v1. Geen analytics- of advertentie-SDK's.
- Geen externe Swift packages tenzij ik daar expliciet om vraag.
- Architectuur: feature-mappen (`Today`, `Discover`, `Plan`, `Shopping`, `Profile`, `Supplements`), pure rekenlogica in `Core/` als structs/functies zonder UI-afhankelijkheden, zodat alles unit-testbaar is.
- Seed-data als JSON in de app-bundle (`Resources/Data/`): `foods.json`, `plans.json`, `supplements.json`, `prices.json`, `packs.json`, `stores.json`. Haal de inhoud uit het prototype (arrays `RAW`, `POOL`, `POOL_BUDGET`, `SUPPS`, `PRICE`, `CAT_PRICE`, `PACK`, `STORES`) met een klein script in `scripts/`, niet met de hand overtypen.
- Previews met `#Preview` (niet `PreviewProvider`).
- `Core/`, `Models/` en `Resources/Data/` zijn ook een Swift package (`Package.swift` in de hoofdmap): `swift test` draait de rekentests zonder simulator. Verwachte waarden in de tests komen uit het prototype zelf via `node scripts/prototype_oracle.mjs`.

## Werkwijze

- Werk in kleine stappen en bouw na elke stap: `xcodebuild -scheme Voedingswijzer -destination 'platform=iOS Simulator,name=iPhone 17' build` (pas de simulatornaam aan aan wat `xcrun simctl list devices` toont).
- Draai na elke wijziging in `Core/` de tests. Schrijf de test eerst voor rekenregels.
- Commit na elke afgeronde fase met een duidelijke Engelse commit message.
- Twijfel je over gedrag: kijk in het prototype. Staat het daar niet in: vraag het mij, gok niet.
- Verander nooit stilzwijgend een formule hieronder.

## Rekenregels (exact overnemen uit het prototype)

**Doelen (`Core/Targets.swift`)**
- BMR: als gebruiker een gemeten BMR invult (>0) → die. Anders, als vetpercentage bekend: Katch-McArdle `370 + 21.6 × vetvrije massa`. Anders Mifflin-St Jeor (man +5, vrouw −161).
- TDEE = BMR × activiteit (1.2 / 1.375 / 1.55 / 1.725 / 1.9).
- Kcal-doel = eigen kcal-doel als >0, anders TDEE × doelfactor (recompositie 0.85, afvallen 0.8, rustig afvallen 0.9, behouden 1.0, opbouwen 1.1), afgerond op 10.
- Eiwit = g/kg × gewicht. Vet = 27 % van kcal ÷ 9. Koolhydraten = rest ÷ 4.
- Micro's per geslacht en leeftijd: zie `targets()` in het prototype (vezels, vit C, A, D, B12, foliumzuur, ijzer, calcium, magnesium, kalium, zink).
- Toon in Profiel het tekort t.o.v. TDEE en het verwachte tempo (tekort × 7 ÷ 7700 kg/week) met de drie teksten uit het prototype.

**Voedzaamheidsscore (`Core/NutrientScore.swift`)**
- Voor 12 stoffen (eiwit, vezels + 10 micro's): `ratio = (waarde/kcal) ÷ (dagdoel/kcal-doel)`, afgetopt op 3, gedeeld door 3, gemiddeld × 100. Labels “Topkeuze” (score ≥ 50 en ≤ 150 kcal/100 g) en “Calorierijk” (≥ 350 kcal/100 g).

**Weekplan (`Core/PlanEngine.swift`)**
- 5 momenten: ontbijt, lunch, tussendoor, avondeten, avondsnack. Twee menu’s: “Gangbaar & goedkoop” (standaard) en “Gevarieerd”; keuzes per menu apart opslaan.
- Opties per dag (maandag = 0): `pool[(w*3 + i + floor(w*3/n)) % n]` voor i = 0…2.
- Dagfactor = kcal-doel ÷ kcal van gekozen maaltijden, begrensd 0.7–1.4. Portie = max(5, afgerond op 5 g).
- **Vandaag live**: als de getoonde weekdag gelijk is aan de logdag, tel al gegeten kcal (alles wat gelogd is). Momenten zijn “gegeten” als er items met dat moment gelogd zijn of als de gebruiker “Al gegeten, zelf ingevoerd” tikt. Resterende momenten schalen naar (doel − gegeten) ÷ resterende kcal, begrensd 0.4–1.6. Banners en waarschuwingen zoals in het prototype; melding als een log de gebruiker > 25 kcal boven het doel brengt.

**Boodschappen (`Core/ShoppingList.swift`)**
- Tel de gekozen opties van alle 7 dagen op (met de basis-dagfactor per dag).
- Omrekenen naar verpakkingen via `packs.json`: `[schap, enkelvoud, meervoud, gram per verpakking, omrekening gekocht→plangewicht]`; aantal = max(1, ceil(nodig ÷ verpakking − 0.08)).
- Groeperen per schap in de volgorde van `AISLES`. Afvinken per product, met “Alle vinkjes weghalen”.
- Prijs per verpakking = gram × omrekening ÷ 1000 × prijs/kg. Supermarktindex uit `stores.json` (Consumentenbond, peildatum 6 mei 2026). Toon “aan de kassa” en “deze week opgegeten”. Altijd het label dat het een schatting is, zonder aanbiedingen.

**Supplementen (`Core/Supplements.swift`)**
- Standaardlijst + eigen supplementen, aan/uit en dosis in Profiel. Afvinken per dag. Creatine: aparte kaart met reeks (“x dagen op rij”: tel terug vanaf vandaag, of vanaf gisteren als vandaag nog niet is afgevinkt) en de laatste 7 dagen. Supplementen met een gekoppelde voedingsstof tellen mee in de dagtotalen.

## Datamodel (SwiftData)

`Profile` (singleton), `FoodItem` (alleen eigen producten; standaardproducten komen uit JSON), `LogEntry` (datum, naam, gram, voedingswaarden per 100 g als snapshot, optioneel `slot`), `SlotDone` (datum, slot), `SupplementIntake` (datum, supplement-id), `PlanChoice` (menu, weekdag, slot, index), `ShoppingTick` (productnaam). Sla bij een log altijd een snapshot van de voedingswaarden op, zodat oude dagen niet veranderen als de database wordt bijgewerkt.

## Schermen

Tab-bar met 4 tabs: **Vandaag**, **Ontdekken**, **Plan**, **Profiel**. Boodschappen zit in Plan (eigen scherm via knop). Gebruik `NavigationStack`, `List`/`Form` waar logisch, SF Symbols, `.sensoryFeedback` bij afvinken. Ondersteun Dynamic Type, VoiceOver-labels op alle knoppen zonder tekst, en donkere modus.

## Niet doen

- Geen medische claims (“behandelt”, “geneest”). Toon in Profiel en bij de eerste start: “Schattingen, geen medisch advies.”
- Geen gezondheidsdata naar iCloud, servers of derden.
- Niet scrapen van supermarktwebsites.
- Geen placeholder- of nepdata tonen als echte data.

## Bronvermelding (verplicht in een “Over”-scherm)

- Consumentenbond prijspeiling supermarkten, peildatum 6 mei 2026 (alleen de procentuele verschillen).
- Zodra voedingswaarden uit NEVO komen: “NEVO-online versie 2025/9.0, RIVM, Bilthoven”, waarden ongewijzigd overnemen.
- Bij Open Food Facts (later): ODbL-bronvermelding en een eigen User-Agent.
