// Hier staan alle shirtcategorieën die op de homepage en de voorbeeldenpagina
// worden getoond. Wil je een nieuwe categorie toevoegen (bijvoorbeeld
// "Sportteams" of "Vrijgezellenfeest")? Kopieer gewoon een van de blokken
// hieronder, geef het een nieuwe "slug" (gebruikt in de link) en vul je eigen
// tekst en afbeeldingen in. Meer hoef je nergens aan te passen — de
// homepage en de voorbeeldenpagina lezen deze lijst automatisch uit.
//
// Afbeeldingen staan in public/images/shirts/ — vervang die bestanden door
// je eigen foto's (zelfde bestandsnaam, of pas het pad hieronder aan).

export const shirtCategories = [
  {
    slug: "kinderfeestje",
    title: "Kinderfeestjes",
    image: "/images/shirts/kinderfeestje-1.svg",
    description:
      "Een shirt met de naam of leeftijd van de jarige erop, of voor de hele vriendengroep dezelfde opdruk. Leuk om te dragen tijdens het feestje en daarna nog jaren in de kast.",
    examples: [
      "Verjaardagsshirt met naam en leeftijd",
      "Zelfde shirt voor alle vriendjes/vriendinnetjes",
      "Themafeestjes (prinsessen, dino's, voetbal, noem maar op)",
      "Traktatie-shirtjes voor op school",
    ],
  },
  {
    slug: "bedrijven",
    title: "Bedrijven & teams",
    image: "/images/shirts/bedrijf-1.svg",
    description:
      "Poloshirts of t-shirts met logo, voor op de vloer, achter de kassa of tijdens een personeelsuitje. Ook leuk als klein bedankje voor je team.",
    examples: [
      "Personeelsshirts met bedrijfslogo",
      "Herkenbare shirts voor evenementen en beurzen",
      "Teamshirts voor sportclubs of bedrijfstoernooien",
      "Vaste borduring op poloshirts voor dagelijks gebruik",
    ],
  },
  {
    slug: "familiedag",
    title: "Familiedagen & groepen",
    image: "/images/shirts/familiedag-1.svg",
    description:
      "Iedereen in hetzelfde shirt op de familiedag, reünie of stapavond met vrienden. Leuk voor op de foto en je herkent elkaar meteen in de menigte.",
    examples: [
      "Familienaam of jaartal op de rug",
      "Reünies en vriendengroepen",
      "Vrijgezellenfeesten en groepsuitjes",
      "Herdenkingsshirts of jubileumshirts",
    ],
  },
  {
    slug: "eigen-ontwerp",
    title: "Eigen ontwerp",
    image: "/images/shirts/eigen-ontwerp-1.svg",
    description:
      "Heb je zelf al een idee, tekening of logo? Stuur het mee en ik kijk wat er mogelijk is met bedrukking of borduring. Geen idee nog hoe het eruit moet zien? Ook prima, dan denk ik met je mee.",
    examples: [
      "Eigen tekening of logo laten bedrukken",
      "Borduring op maat (naam, initialen, klein logo)",
      "Combinatie van print en borduring op één shirt",
      "Hulp bij het uitwerken van een ontwerpidee",
    ],
  },
];
