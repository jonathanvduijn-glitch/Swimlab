# Website — zelfgemaakte shirts

Deze website is gebouwd met React + Vite. Hieronder staat waar je zelf dingen
kunt aanpassen, zonder dat je de hele code hoeft te snappen.

## Starten

```bash
npm install
npm run dev
```

Dan is de site lokaal te bekijken op het adres dat in de terminal verschijnt
(meestal `http://localhost:5173`).

Voor een productieversie (bijvoorbeeld om te uploaden naar hosting zoals
Netlify of Vercel):

```bash
npm run build
```

Dit maakt een map `dist/` met de kant-en-klare website.

## Waar pas ik teksten aan?

- **Homepage**: `src/pages/Home.jsx`
- **Shirtvoorbeelden pagina**: teksten per categorie staan niet op de pagina
  zelf, maar in `src/data/shirtCategories.js` (zie hieronder)
- **Over mij**: `src/pages/OverOns.jsx`
- **Contact**: `src/pages/Contact.jsx` en de contactgegevens in
  `src/data/siteInfo.js`
- **Bedrijfsnaam, e-mail, telefoon**: allemaal op één plek in
  `src/data/siteInfo.js`

## Waar vervang ik afbeeldingen?

Alle afbeeldingen staan in `public/images/shirts/`. Nu zijn dit nog simpele
tekening-placeholders (SVG-bestanden) met een label erop, zodat duidelijk is
wat er straks moet komen.

Vervang gewoon het bestand door een eigen foto met dezelfde bestandsnaam
(bijv. `kinderfeestje-1.svg` wordt `kinderfeestje-1.jpg`). Verander je de
bestandsnaam of extensie, pas dan ook het pad aan in
`src/data/shirtCategories.js` (voor de voorbeeldcategorieën) of in de
pagina's `Home.jsx` / `OverOns.jsx` (voor de hero-afbeelding en de foto op de
over-mij pagina).

## Hoe voeg ik een nieuw shirtvoorbeeld / categorie toe?

Open `src/data/shirtCategories.js`. Daar staat een lijst met blokken, één per
categorie. Kopieer een bestaand blok, geef het een eigen `slug` (wordt
gebruikt in de link naar het offerteformulier), en vul je eigen titel,
afbeelding, beschrijving en voorbeelden in. De homepage en de
voorbeeldenpagina lezen deze lijst automatisch uit — je hoeft verder niets
aan te passen.

## Hoe maak ik het offerteformulier (en het contactformulier) echt werkend?

Op dit moment worden de formuliergegevens alleen naar de browserconsole
geschreven (open de ontwikkelaarstools in de browser om dat te zien) — er
wordt nog geen e-mail verstuurd. In `src/pages/Offerte.jsx` staat in de
functie `handleSubmit` een uitgebreide toelichting met drie opties:

1. **Formspree** (makkelijkst): maak gratis een formulier aan op
   [formspree.io](https://formspree.io), en vervang de `console.log`-regel
   door een `fetch` naar jouw eigen Formspree-endpoint.
2. **Netlify Forms**: als je gaat hosten via Netlify, kun je
   `data-netlify="true"` toevoegen aan het `<form>`-element.
3. **Eigen backend / e-mailservice**: stuur de gegevens met `fetch()` naar
   je eigen API.

Dezelfde aanpak werkt voor het contactformulier in `src/pages/Contact.jsx`.

De maten en aantallen die een klant invult, staan al helemaal klaar in de
variabelen `form`, `sizeCounts` en `totaalAantal` — die hoef je alleen nog
maar mee te sturen naar de dienst die je kiest.

## Maten aanpassen

Wil je een maat toevoegen of verwijderen uit het offerteformulier? Pas de
lijst aan in `src/data/sizes.js`. Het formulier past zich automatisch aan.

## Later uitbreiden met een webshop

De site is nu gericht op offertes aanvragen, maar is zo opgebouwd dat een
webshop later toegevoegd kan worden: de shirtcategorieën staan al los in een
databestand (`src/data/shirtCategories.js`), en elke categorie heeft al een
duidelijke plek voor een prijs of variant als je die later wilt toevoegen.
