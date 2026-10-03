# Prompts voor Claude Code

Plak deze prompts één voor één in Claude Code, in de map van je Xcode-project. Wacht steeds tot een fase klaar is, test de app in de simulator en start dan pas de volgende. Begin elke fase in een nieuwe sessie (`/clear`) zodat Claude met een frisse context werkt; `CLAUDE.md` wordt automatisch ingelezen.

Tip: begin een grote fase in **plan mode** (Shift+Tab tot je “plan mode” ziet). Dan laat Claude eerst een plan zien dat je kunt goedkeuren voordat er code wordt geschreven.

---

## Fase 0 – Startprompt (eenmalig)

```
Lees CLAUDE.md en reference/voedingswijzer-prototype.html volledig.

Geef me daarna, voordat je code schrijft:
1. Een korte samenvatting van wat de app doet, in je eigen woorden.
2. De mappenstructuur die je voorstelt.
3. Een lijst van alle rekenregels die je in het prototype vindt, met de functie waar ze staan.
4. Alles wat onduidelijk of tegenstrijdig is tussen CLAUDE.md en het prototype.

Controleer ook mijn ontwikkelomgeving: draai `xcodebuild -version`, `swift --version`, `xcrun simctl list devices available` en `git status`, en vertel me of alles klaarstaat. Schrijf nog geen code.
```

## Fase 1 – Data en rekenkern

```
Fase 1: data en rekenkern, nog geen UI.

1. Schrijf scripts/extract_data.mjs (Node) dat de arrays RAW, POOL, POOL_BUDGET, SUPPS, PRICE, CAT_PRICE, PACK, AISLES en STORES uit reference/voedingswijzer-prototype.html haalt en als nette JSON wegschrijft naar Voedingswijzer/Resources/Data/. Draai het en controleer dat het aantal producten (134) en maaltijden klopt.
2. Maak Codable-modellen en een DataStore die deze JSON uit de bundle laadt.
3. Implementeer in Core/: Targets, NutrientScore, PlanEngine (inclusief live-schaling van de rest van de dag), ShoppingList (verpakkingen, schappen, prijzen) en Supplements (incl. creatine-reeks).
4. Schrijf unit tests (Swift Testing) die de uitkomsten van het prototype nabootsen. Gebruik als referentie: man, 35 jaar, 184 cm, 99,3 kg, 15,5 % vet, BMR 2182, activiteit 1,55, eiwit 2,0 g/kg, eigen kcal-doel 2600 → eiwit 199 g. Test ook: dagfactor-grenzen, portie-afronding, verpakkingsaantallen en de creatine-reeks.
5. Draai alle tests tot ze groen zijn.
```

## Fase 2 – Opslag en Profiel

```
Fase 2: SwiftData-modellen uit CLAUDE.md en het Profiel-scherm.

- Profiel met alle velden uit het prototype (geslacht, leeftijd, lengte, gewicht, vet %, gemeten BMR, activiteit, doel, eigen kcal-doel, eiwit per kg), standaard ingevuld met mijn waarden uit Fase 1.
- Toon de berekende doelen en de tekst over tekort en tempo.
- Sectie “Mijn supplementen” (aan/uit, dosis, eigen supplement toevoegen/verwijderen).
- Een “Over”-scherm met bronvermelding en “Schattingen, geen medisch advies.”
- Tab-bar met de 4 tabs (de andere tabs mogen nog leeg zijn).
Bouw, draai in de simulator en maak een screenshot van Profiel om te controleren.
```

## Fase 3 – Ontdekken

```
Fase 3: tab Ontdekken.

- Zoeken, categoriefilters, sorteren (meest voedzaam per kcal, minste kcal, meeste eiwit per kcal, meeste vezels per kcal).
- Rij per product: scorering, naam, labels Topkeuze/Calorierijk, eiwit en vezels, kcal/100 g, het 12-delige voedingsstoffenbalkje.
- Detail: alle voedingswaarden per 100 g, hoeveelheid in gram met live kcal/eiwit, knop “Toevoegen” naar de gekozen dag. Melding als je boven je doel komt.
- Eigen product toevoegen en verwijderen.
Controleer met screenshots in licht én donker.
```

## Fase 4 – Vandaag en supplementen

```
Fase 4: tab Vandaag.

- Dagnavigatie (vorige/volgende, niet in de toekomst).
- Kcal over/boven doel, voortgangsbalk, eiwit/koolhydraten/vet/vezels.
- Supplementen: creatine-kaart met reeks en 7-dagenstipjes, tegels voor de overige supplementen, afvinken met haptische feedback.
- Vitamines & mineralen als % van dagdoel (inclusief supplementen), oranje bij < 50 %.
- Gegeten items met verwijderen (veeg naar links).
Schrijf UI-tests voor: product toevoegen, verwijderen, supplement afvinken.
```

## Fase 5 – Weekplan

```
Fase 5: tab Plan.

- Keuze menu “Gangbaar & goedkoop” / “Gevarieerd”, dagkiezer ma–zo (opent op vandaag).
- Per moment 3 opties, ingrediëntenlijst met geschaalde porties, “loggen” en “Al gegeten, zelf ingevoerd”.
- Live-gedrag voor vandaag precies zoals in CLAUDE.md: gegeten momenten afgevinkt, rest geschaald, banners en waarschuwingen.
- Dagtotalen (verwacht), schakelaar “Porties afstemmen op mijn kcal-doel”, “Rest van de dag loggen”.
- De tips over recompositie onderaan.
Test het scenario: alleen ontbijt gelogd → rest van de dag komt rond 2600 kcal uit.
```

## Fase 6 – Boodschappen

```
Fase 6: boodschappenlijst als eigen scherm vanuit Plan.

- Supermarkten in de buurt aan/uit (13 ketens), vergelijking per week met “Goedkoopst”, kassa vs. opgegeten.
- Lijst per schap in verpakkingen (bijv. “2 broden (800 g)”), prijs per regel bij de goedkoopste gekozen supermarkt, afvinken, teller “x/y in je mandje”, alles weghalen.
- Deelknop (ShareLink) die de lijst als platte tekst deelt, zodat ik hem naar iemand kan sturen.
- Duidelijk label dat prijzen schattingen zijn.
```

## Fase 7 – Afwerking en App Store-klaar

```
Fase 7: afwerking.

- Controleer toegankelijkheid (VoiceOver-labels, Dynamic Type tot XXL, contrast).
- Voeg PrivacyInfo.xcprivacy toe met de juiste required-reason API's die de app gebruikt (bijv. UserDefaults) en NSPrivacyTracking = false, zonder verzamelde datatypes.
- Lege toestanden, foutmeldingen en eerste-start-scherm met de disclaimer.
- App-icoon placeholder en launch screen.
- Loop alle code na op force unwraps, Swift 6-concurrencywaarschuwingen en ongebruikte code.
- Maak een lijst van wat ik zelf nog moet doen in App Store Connect (zie LEESMIJ.md).
```

## Later (optioneel, aparte fases)

- **Apple Gezondheid**: gewicht lezen, gegeten kcal en eiwit schrijven (alleen echte, gelogde waarden). Vraag pas toestemming wanneer de gebruiker de functie aanzet.
- **Barcode scannen** met VisionKit `DataScannerViewController` + Open Food Facts API (eigen User-Agent, caching, ODbL-bronvermelding).
- **NEVO 2025/9.0** importeren als vervanging van de schattingswaarden.
- **Widget** met kcal over en creatine-vinkje.
