import ShirtCategoryCard from "../components/ShirtCategoryCard";
import { shirtCategories } from "../data/shirtCategories";

// Deze pagina toont automatisch alle categorieën uit
// src/data/shirtCategories.js, inclusief de voorbeelden per categorie.
// Nieuwe categorie toevoegen? Dat hoeft alleen in dat databestand.
export default function Voorbeelden() {
  return (
    <section>
      <div className="container">
        <div className="page-hero section-header" style={{ textAlign: "left", maxWidth: "none" }}>
          <h1>Shirtvoorbeelden</h1>
          <p>
            Een indruk van wat er hier zoal gemaakt wordt. De foto's hieronder
            zijn nog placeholders — die worden binnenkort vervangen door
            echte foto's van gemaakte shirts.
          </p>
        </div>

        <div className="card-grid">
          {shirtCategories.map((category) => (
            <ShirtCategoryCard key={category.slug} category={category} showExamples />
          ))}
        </div>
      </div>
    </section>
  );
}
