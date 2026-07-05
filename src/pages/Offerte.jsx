import { useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { shirtCategories } from "../data/shirtCategories";
import { adultSizes, kidsSizes } from "../data/sizes";

// Alle maten samen, gebruikt om het aantallen-object op te bouwen.
const allSizes = [...adultSizes, ...kidsSizes];

function emptySizeCounts() {
  return Object.fromEntries(allSizes.map((size) => [size, ""]));
}

export default function Offerte() {
  const [searchParams] = useSearchParams();
  const voorkeurSoort = searchParams.get("soort") || "";

  const [form, setForm] = useState({
    naam: "",
    email: "",
    telefoon: "",
    soort: voorkeurSoort,
    afwerking: "",
    kleur: "",
    opmerking: "",
  });
  const [sizeCounts, setSizeCounts] = useState(emptySizeCounts);
  const [submitted, setSubmitted] = useState(false);

  const totaalAantal = useMemo(
    () =>
      Object.values(sizeCounts).reduce(
        (sum, value) => sum + (parseInt(value, 10) || 0),
        0,
      ),
    [sizeCounts],
  );

  function updateField(field) {
    return (event) => setForm((prev) => ({ ...prev, [field]: event.target.value }));
  }

  function updateSize(size) {
    return (event) => {
      const value = event.target.value;
      if (value !== "" && (!/^\d+$/.test(value) || Number(value) < 0)) return;
      setSizeCounts((prev) => ({ ...prev, [size]: value }));
    };
  }

  function handleSubmit(event) {
    event.preventDefault();

    // ------------------------------------------------------------------
    // Hier komt later het versturen van de offerte-aanvraag.
    // Dit formulier verzendt nu nog niets — het is klaar om te koppelen
    // aan bijvoorbeeld:
    //
    //  1) Formspree: maak een gratis form aan op formspree.io, en vervang
    //     de regel hieronder door een fetch naar je eigen endpoint:
    //
    //     await fetch("https://formspree.io/f/JOUW_FORM_ID", {
    //       method: "POST",
    //       headers: { Accept: "application/json" },
    //       body: new FormData(event.target),
    //     });
    //
    //  2) Netlify Forms: voeg data-netlify="true" en een verborgen
    //     form-name input toe aan het <form> element, en zorg dat er ook
    //     een statische kopie van het formulier in public/index.html staat
    //     zodat Netlify het formulier herkent tijdens het bouwen.
    //
    //  3) Een eigen backend/e-mailservice: stuur de data hieronder met
    //     fetch() naar je eigen API endpoint.
    //
    // De volledige formuliergegevens staan al klaar in de variabelen
    // `form`, `sizeCounts` en `totaalAantal` hierboven.
    console.log("Offerte-aanvraag (nog niet verzonden):", { ...form, sizeCounts, totaalAantal });

    setSubmitted(true);
  }

  return (
    <section>
      <div className="container">
        <div className="page-hero section-header" style={{ textAlign: "left", maxWidth: "none" }}>
          <h1>Offerte aanvragen</h1>
          <p>
            Vul in wat je in gedachten hebt, dan kijk ik ernaar en stuur ik je
            een prijs en een berichtje terug. Hoe meer je invult, hoe sneller
            ik een goed voorstel kan doen — maar twijfel je nog over iets?
            Vul gewoon in wat je al weet.
          </p>
        </div>

        {submitted && (
          <p className="form-success">
            Bedankt voor je aanvraag! Dit formulier verstuurt nog geen echte
            e-mail (zie de instructies in de projectcode om dat aan te
            zetten), maar de gegevens zijn hierboven in de browserconsole te
            zien.
          </p>
        )}

        <form className="form-card" onSubmit={handleSubmit}>
          <fieldset>
            <legend>Jouw gegevens</legend>
            <div className="form-grid">
              <div className="field">
                <label htmlFor="naam">Naam</label>
                <input id="naam" name="naam" required value={form.naam} onChange={updateField("naam")} />
              </div>
              <div className="field">
                <label htmlFor="email">E-mailadres</label>
                <input id="email" name="email" type="email" required value={form.email} onChange={updateField("email")} />
              </div>
              <div className="field">
                <label htmlFor="telefoon">Telefoonnummer</label>
                <input id="telefoon" name="telefoon" type="tel" value={form.telefoon} onChange={updateField("telefoon")} />
              </div>
            </div>
          </fieldset>

          <fieldset>
            <legend>Waar gaat het om?</legend>
            <div className="form-grid">
              <div className="field">
                <label htmlFor="soort">Soort aanvraag</label>
                <select id="soort" name="soort" value={form.soort} onChange={updateField("soort")}>
                  <option value="">Maak een keuze</option>
                  {shirtCategories.map((category) => (
                    <option key={category.slug} value={category.slug}>{category.title}</option>
                  ))}
                  <option value="anders">Anders</option>
                </select>
              </div>
              <div className="field">
                <label htmlFor="afwerking">Type afwerking</label>
                <select id="afwerking" name="afwerking" value={form.afwerking} onChange={updateField("afwerking")}>
                  <option value="">Maak een keuze</option>
                  <option value="bedrukking">Bedrukking (Cricut)</option>
                  <option value="borduren">Borduren</option>
                  <option value="nog-niet-zeker">Weet ik nog niet</option>
                </select>
              </div>
              <div className="field">
                <label htmlFor="kleur">Kleur shirt</label>
                <input id="kleur" name="kleur" placeholder="bijv. wit, zwart, zandkleur..." value={form.kleur} onChange={updateField("kleur")} />
              </div>
            </div>

            <div className="field">
              <label htmlFor="opmerking">Opmerking / idee voor ontwerp</label>
              <textarea
                id="opmerking"
                name="opmerking"
                placeholder="Vertel hier over je idee, tekst die erop moet, of stuur straks een voorbeeld mee."
                value={form.opmerking}
                onChange={updateField("opmerking")}
              />
            </div>

            <div className="field">
              <label htmlFor="bestand">Voorbeeld of logo uploaden</label>
              <input id="bestand" name="bestand" type="file" accept="image/*,.pdf" />
              <p className="field-hint">Optioneel — een schets, foto of logo helpt vaak.</p>
            </div>
          </fieldset>

          <fieldset>
            <legend>Maten en aantallen</legend>
            <p className="field-hint" style={{ marginBottom: "1rem" }}>
              Vul bij elke maat in hoeveel shirts je nodig hebt. Weet je het
              aantal per maat nog niet precies? Vul dan een schatting in, dat
              werkt ook prima.
            </p>

            <p style={{ fontWeight: 600, marginBottom: "0.6rem" }}>Volwassenmaten</p>
            <div className="size-grid" style={{ marginBottom: "1.4rem" }}>
              {adultSizes.map((size) => (
                <div className="size-field" key={size}>
                  <label htmlFor={`maat-${size}`}>{size}</label>
                  <input
                    id={`maat-${size}`}
                    name={`aantal_${size}`}
                    type="number"
                    min="0"
                    inputMode="numeric"
                    placeholder="0"
                    value={sizeCounts[size]}
                    onChange={updateSize(size)}
                  />
                </div>
              ))}
            </div>

            <p style={{ fontWeight: 600, marginBottom: "0.6rem" }}>Kindermaten</p>
            <div className="size-grid">
              {kidsSizes.map((size) => (
                <div className="size-field" key={size}>
                  <label htmlFor={`maat-${size}`}>{size}</label>
                  <input
                    id={`maat-${size}`}
                    name={`aantal_${size}`}
                    type="number"
                    min="0"
                    inputMode="numeric"
                    placeholder="0"
                    value={sizeCounts[size]}
                    onChange={updateSize(size)}
                  />
                </div>
              ))}
            </div>

            <div className="total-bar">
              <span>Totaal aantal shirts</span>
              <span>{totaalAantal}</span>
            </div>
          </fieldset>

          <button type="submit" className="btn btn-primary">Offerte aanvragen</button>
          <p className="form-note">
            Na het versturen neem ik zo snel mogelijk contact met je op, meestal binnen een paar dagen.
          </p>
        </form>
      </div>
    </section>
  );
}
