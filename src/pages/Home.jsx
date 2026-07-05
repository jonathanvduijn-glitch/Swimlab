import Button from "../components/Button";
import ShirtCategoryCard from "../components/ShirtCategoryCard";
import { shirtCategories } from "../data/shirtCategories";

// Landingspagina. De introtekst hieronder mag je gerust helemaal herschrijven
// naar je eigen stijl — dit is maar een voorbeeld.
export default function Home() {
  return (
    <>
      <section className="hero">
        <div className="container hero-grid">
          <div>
            <h1>Shirts die niet uit een fabriek komen, maar van mijn keukentafel.</h1>
            <p>
              Ik maak shirts met een eigen opdruk of borduring — voor een
              kinderfeestje, een bedrijf, of gewoon omdat de hele familie op
              de foto wil in hetzelfde shirt. Alles wordt hier zelf bedrukt
              met de Cricut of geborduurd, met aandacht voor het resultaat.
            </p>
            <ul>
              <li>Zelfgemaakt, geen massaproductie</li>
              <li>Voor kinderfeestjes, bedrijven en familiedagen</li>
              <li>Klein begonnen, met aandacht gemaakt</li>
              <li>Heb je zelf een idee? Stuur het gewoon mee</li>
            </ul>
            <div className="btn-row">
              <Button to="/voorbeelden" variant="primary">Bekijk voorbeelden</Button>
              <Button to="/offerte" variant="secondary">Vraag een offerte aan</Button>
            </div>
          </div>
          <div className="hero-image">
            {/* Vervang dit bestand later door een echte foto van je werk */}
            <img src="/images/shirts/hero.svg" alt="Zelfgemaakte shirts met opdruk en borduring" />
          </div>
        </div>
      </section>

      <section className="section-alt">
        <div className="container">
          <div className="section-header">
            <h2>Een paar voorbeelden</h2>
            <p>Zomaar wat shirts die hier al eens gemaakt zijn. Op de voorbeeldenpagina staat meer.</p>
          </div>
          <div className="card-grid">
            {shirtCategories.map((category) => (
              <ShirtCategoryCard key={category.slug} category={category} />
            ))}
          </div>
        </div>
      </section>

      <section>
        <div className="container section-header">
          <h2>Zelf een idee?</h2>
          <p>
            Je hoeft niet precies te weten hoe het eruit moet komen te zien.
            Stuur een schets, een foto of gewoon een omschrijving, en ik denk
            met je mee over wat er mogelijk is met bedrukking of borduring.
          </p>
          <div className="btn-row" style={{ justifyContent: "center" }}>
            <Button to="/offerte" variant="primary">Vraag een offerte aan</Button>
          </div>
        </div>
      </section>
    </>
  );
}
