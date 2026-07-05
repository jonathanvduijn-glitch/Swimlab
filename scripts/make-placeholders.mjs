// Eenmalig hulpscript om placeholder-afbeeldingen te genereren.
// Niet nodig om te draaien tijdens normaal gebruik van de site.
import { writeFileSync, mkdirSync } from "node:fs";

const shirtPath =
  "M 70 40 L 100 20 L 130 40 L 165 55 L 150 90 L 130 80 L 130 180 L 70 180 L 70 80 L 50 90 L 35 55 Z";

const items = [
  { file: "kinderfeestje-1.svg", bg: "#F3D9B1", accent: "#C97C5D", label: "Kinderfeestje shirt" },
  { file: "kinderfeestje-2.svg", bg: "#F6E3C3", accent: "#9CAF88", label: "Kinderfeestje shirt" },
  { file: "bedrijf-1.svg", bg: "#E7E1D3", accent: "#3E362E", label: "Bedrijfsshirt" },
  { file: "bedrijf-2.svg", bg: "#EFE9DC", accent: "#5C6B57", label: "Teamshirt" },
  { file: "familiedag-1.svg", bg: "#E3EBDD", accent: "#9CAF88", label: "Familiedag shirt" },
  { file: "familiedag-2.svg", bg: "#EFE3D0", accent: "#C97C5D", label: "Groepsshirt" },
  { file: "eigen-ontwerp-1.svg", bg: "#F7EFE1", accent: "#C97C5D", label: "Eigen ontwerp" },
  { file: "eigen-ontwerp-2.svg", bg: "#EFE3D0", accent: "#3E362E", label: "Eigen ontwerp" },
  { file: "hero.svg", bg: "#F3EAD6", accent: "#C97C5D", label: "Zelfgemaakte shirts" },
  { file: "over-ons.svg", bg: "#E7E1D3", accent: "#9CAF88", label: "Aan het werk" },
];

mkdirSync("public/images/shirts", { recursive: true });

for (const { file, bg, accent, label } of items) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" role="img" aria-label="${label} (placeholder)">
  <rect width="400" height="400" rx="24" fill="${bg}" />
  <g transform="translate(100,90) scale(1.15)">
    <path d="${shirtPath}" fill="${accent}" opacity="0.9" />
  </g>
  <text x="200" y="330" text-anchor="middle" font-family="Verdana, sans-serif" font-size="18" fill="#3E362E" opacity="0.75">${label}</text>
  <text x="200" y="355" text-anchor="middle" font-family="Verdana, sans-serif" font-size="13" fill="#3E362E" opacity="0.5">placeholder — vervang me</text>
</svg>`;
  writeFileSync(`public/images/shirts/${file}`, svg);
}

console.log("Placeholders aangemaakt in public/images/shirts/");
