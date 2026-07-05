import Button from "../components/Button";

// Placeholdertekst — pas dit aan naar je eigen verhaal. Dit hoeft geen
// perfect geschreven tekst te zijn, het mag gewoon klinken zoals jij praat.
export default function OverOns() {
  return (
    <section>
      <div className="container about-grid">
        <img src="/images/shirts/over-ons.svg" alt="Aan het werk met de Cricut en borduurmachine" />

        <div>
          <h1>Over mij</h1>
          <p>
            Ik ben begonnen met een Cricut op de keukentafel en een idee: ik
            wilde shirts maken die net wat persoonlijker zijn dan wat je
            standaard in een webshop bestelt. Inmiddels is daar borduren
            bijgekomen, en maak ik shirts voor kinderfeestjes, bedrijven en
            iedereen die iets leuks zoekt voor een groep.
          </p>
          <p>
            Alles wordt hier zelf gemaakt, in kleine oplages. Geen grote
            fabriek, geen duizenden shirts per dag — wel tijd en aandacht
            voor elk ontwerp. Daardoor kan ik ook echt meedenken: heb je een
            vaag idee, een logo dat niet helemaal past, of twijfel je tussen
            print en borduring? Dan kijken we daar samen naar.
          </p>

          <ul className="value-list">
            <li>Handgemaakt, met de Cricut en de borduurmachine</li>
            <li>Kleine oplages, geen massaproductie</li>
            <li>Persoonlijk contact — je mailt of belt met mij, niet met een klantenservice</li>
            <li>Ik denk mee over je ontwerp, ook als je nog geen kant-en-klaar idee hebt</li>
          </ul>

          <p>
            Benieuwd of ik iets voor jou kan maken? Stuur gerust een berichtje,
            ook als je nog niet precies weet wat je zoekt.
          </p>

          <Button to="/offerte" variant="primary">Vraag een offerte aan</Button>
        </div>
      </div>
    </section>
  );
}
