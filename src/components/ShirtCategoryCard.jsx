import Button from "./Button";

// Toont één shirtcategorie. Wordt gebruikt op de homepage (kort) en op de
// voorbeeldenpagina (met alle toepassingen erbij, via showExamples).
export default function ShirtCategoryCard({ category, showExamples = false }) {
  return (
    <div className="card">
      <div className="card-image">
        <img src={category.image} alt={category.title} loading="lazy" />
      </div>
      <div className="card-body">
        <h3>{category.title}</h3>
        <p>{category.description}</p>

        {showExamples && (
          <ul className="card-examples">
            {category.examples.map((example) => (
              <li key={example}>{example}</li>
            ))}
          </ul>
        )}

        <Button to={`/offerte?soort=${category.slug}`} variant="primary">
          Offerte aanvragen
        </Button>
      </div>
    </div>
  );
}
