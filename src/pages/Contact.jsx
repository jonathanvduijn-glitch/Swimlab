import { useState } from "react";
import { siteInfo } from "../data/siteInfo";

export default function Contact() {
  const [form, setForm] = useState({ naam: "", email: "", bericht: "" });
  const [submitted, setSubmitted] = useState(false);

  function updateField(field) {
    return (event) => setForm((prev) => ({ ...prev, [field]: event.target.value }));
  }

  function handleSubmit(event) {
    event.preventDefault();
    // Zelfde verhaal als bij het offerteformulier: dit verstuurt nog niets.
    // Koppel dit later aan Formspree, Netlify Forms of je eigen backend
    // (zie de uitgebreide toelichting in src/pages/Offerte.jsx).
    console.log("Contactbericht (nog niet verzonden):", form);
    setSubmitted(true);
  }

  return (
    <section>
      <div className="container">
        <div className="page-hero section-header" style={{ textAlign: "left", maxWidth: "none" }}>
          <h1>Contact</h1>
          <p>
            Heb je een vraag, een idee, of wil je gewoon even overleggen wat
            mogelijk is? Stuur een bericht of mail/bel me rechtstreeks — je
            mag altijd een idee sturen, ook als het nog niet uitgewerkt is.
          </p>
        </div>

        <div className="about-grid">
          <div>
            {submitted && (
              <p className="form-success">
                Bedankt voor je bericht! (Dit formulier is nog niet gekoppeld
                aan e-mail — zie de projectcode voor hoe je dat aanzet.)
              </p>
            )}

            <form className="form-card" onSubmit={handleSubmit}>
              <div className="field" style={{ marginBottom: "1.2rem" }}>
                <label htmlFor="c-naam">Naam</label>
                <input id="c-naam" name="naam" required value={form.naam} onChange={updateField("naam")} />
              </div>
              <div className="field" style={{ marginBottom: "1.2rem" }}>
                <label htmlFor="c-email">E-mailadres</label>
                <input id="c-email" name="email" type="email" required value={form.email} onChange={updateField("email")} />
              </div>
              <div className="field" style={{ marginBottom: "1.2rem" }}>
                <label htmlFor="c-bericht">Bericht of idee</label>
                <textarea id="c-bericht" name="bericht" required value={form.bericht} onChange={updateField("bericht")} />
              </div>
              <button type="submit" className="btn btn-primary">Versturen</button>
            </form>
          </div>

          <div>
            <h3>Rechtstreeks contact</h3>
            <p>
              E-mail: <a href={`mailto:${siteInfo.email}`}>{siteInfo.email}</a>
              <br />
              Telefoon: <a href={`tel:${siteInfo.telefoon}`}>{siteInfo.telefoon}</a>
              <br />
              Instagram: {siteInfo.instagram}
            </p>
            <p>
              Ik reageer meestal binnen een paar dagen. Zit er haast bij? Zet dat er dan even bij in je bericht.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
