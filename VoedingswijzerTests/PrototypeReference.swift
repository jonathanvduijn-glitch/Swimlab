@testable import Voedingswijzer

// Reference values produced by the prototype's own JavaScript (scripts/prototype_oracle.mjs)
// for the default profile, both menus and the default (first) option everywhere.
// Regenerate with that script when the prototype changes; do not edit by hand.
enum PrototypeReference {
    typealias Portion = (name: String, grams: Double)

    struct ShoppingReference {
        let name: String
        let grams: Double
        let aisle: String
        let label: String
        let cost: Double
        let used: Double
    }

    static let budgetDayFactors: [Double] = [1.017832, 1.062243, 1.079869, 1.092667, 1.179941, 1.048281, 1.063939]
    static let variedDayFactors: [Double] = [1.010828, 1.102629, 1.005958, 1.066995, 1.038837, 1.072718, 1.032935]

    /// Option names per weekday for the budget menu.
    static let budgetOptions: [[MealSlot: [String]]] = [
        [
            .breakfast: ["Brood met ei en kip", "Havermout met melk", "Kwark met havermout en appel"],
            .lunch: ["Broodjes kip en ei", "Brood met tonijnsalade", "Koude pastasalade met kip"],
            .snack: ["Kwark met banaan", "Boterham met kaas en melk", "Eitje met kip en appel"],
            .dinner: ["Kip met rijst en groente", "Boerenkoolstamppot met gehakt", "Spaghetti bolognese"],
            .eveningSnack: ["Kwark met appel", "Hüttenkäse met komkommer", "Yoghurt met kwark"],
        ],
        [
            .breakfast: ["Boterhammen met kaas en kip", "Yoghurt met muesli", "Roerei met roggebrood"],
            .lunch: ["Bruinebonensalade met ei", "Wraps met gehakt", "Roggebrood met sardines"],
            .snack: ["Kwark met pinda's", "Rijstwafels met hüttenkäse", "Melk met banaan en pinda's"],
            .dinner: ["Aardappels, kipdij en sperziebonen", "Nasi met kip en ei", "Chili con carne"],
            .eveningSnack: ["Eitje met kipfilet", "Kwark met havermout", "Boterham met hüttenkäse"],
        ],
        [
            .breakfast: ["Pindakaasboterham met melk", "Wentelteefjes met kwark", "Overnight oats"],
            .lunch: ["Kwark met muesli en rijstwafels", "Omelet met brood", "Witte bonen op toast"],
            .snack: ["Boterham met kaas en melk", "Eitje met kip en appel", "Kwark met pinda's"],
            .dinner: ["Zuurkoolstamppot met gehakt", "Macaroni met kip", "Witvis met spinazie en aardappels"],
            .eveningSnack: ["Hüttenkäse met komkommer", "Yoghurt met kwark", "Eitje met kipfilet"],
        ],
        [
            .breakfast: ["Havermout met melk", "Kwark met havermout en appel", "Boterhammen met kaas en kip"],
            .lunch: ["Brood met tonijnsalade", "Koude pastasalade met kip", "Bruinebonensalade met ei"],
            .snack: ["Rijstwafels met hüttenkäse", "Melk met banaan en pinda's", "Kwark met banaan"],
            .dinner: ["Hutspot met gehakt", "Bruine bonen met rijst en kip", "Ovenschotel kip en broccoli"],
            .eveningSnack: ["Kwark met havermout", "Boterham met hüttenkäse", "Kwark met appel"],
        ],
        [
            .breakfast: ["Yoghurt met muesli", "Roerei met roggebrood", "Pindakaasboterham met melk"],
            .lunch: ["Wraps met gehakt", "Roggebrood met sardines", "Kwark met muesli en rijstwafels"],
            .snack: ["Eitje met kip en appel", "Kwark met pinda's", "Rijstwafels met hüttenkäse"],
            .dinner: ["Pasta met tonijn", "Boerenomelet met aardappels", "Kip met rijst en groente"],
            .eveningSnack: ["Yoghurt met kwark", "Eitje met kipfilet", "Kwark met havermout"],
        ],
        [
            .breakfast: ["Wentelteefjes met kwark", "Overnight oats", "Brood met ei en kip"],
            .lunch: ["Omelet met brood", "Witte bonen op toast", "Broodjes kip en ei"],
            .snack: ["Melk met banaan en pinda's", "Kwark met banaan", "Boterham met kaas en melk"],
            .dinner: ["Spaghetti bolognese", "Aardappels, kipdij en sperziebonen", "Nasi met kip en ei"],
            .eveningSnack: ["Boterham met hüttenkäse", "Kwark met appel", "Hüttenkäse met komkommer"],
        ],
        [
            .breakfast: ["Kwark met havermout en appel", "Boterhammen met kaas en kip", "Yoghurt met muesli"],
            .lunch: ["Koude pastasalade met kip", "Bruinebonensalade met ei", "Wraps met gehakt"],
            .snack: ["Kwark met pinda's", "Rijstwafels met hüttenkäse", "Melk met banaan en pinda's"],
            .dinner: ["Chili con carne", "Zuurkoolstamppot met gehakt", "Macaroni met kip"],
            .eveningSnack: ["Eitje met kipfilet", "Kwark met havermout", "Boterham met hüttenkäse"],
        ],
    ]

    /// Scaled portions per moment for every weekday of the budget menu, default choices.
    static let budgetMeals: [[MealSlot: [Portion]]] = [
        [
            .breakfast: [("Volkorenbrood", 105), ("Ei (gekookt)", 155), ("Kipfilet (beleg)", 50), ("Halvarine (verrijkt)", 5), ("Tomaat", 100)],
            .lunch: [("Volkorenbrood", 140), ("Kipfilet (beleg)", 75), ("Ei (gekookt)", 50), ("Hüttenkäse", 100), ("Halvarine (verrijkt)", 5), ("Komkommer", 100), ("Appel", 155)],
            .snack: [("Magere kwark", 255), ("Banaan", 120), ("Pindakaas (100% pinda)", 10)],
            .dinner: [("Kipfilet (gebakken)", 180), ("Witte rijst (gekookt)", 255), ("Broccoli", 155), ("Wortel", 100), ("Sojasaus", 10), ("Olijfolie", 10)],
            .eveningSnack: [("Magere kwark", 255), ("Appel", 100)],
        ],
        [
            .breakfast: [("Volkorenbrood", 150), ("Kaas 30+", 40), ("Kipfilet (beleg)", 55), ("Halvarine (verrijkt)", 5), ("Komkommer", 105), ("Halfvolle melk", 265)],
            .lunch: [("Bruine bonen (gekookt)", 210), ("Ei (gekookt)", 105), ("Tomaat", 105), ("Ui", 30), ("Komkommer", 105), ("Volkorenbrood", 75), ("Olijfolie", 5)],
            .snack: [("Magere kwark", 210), ("Pinda's (ongezouten)", 20), ("Mandarijn", 160)],
            .dinner: [("Aardappel (gekookt)", 320), ("Kipdij (gebakken)", 185), ("Sperziebonen", 265), ("Halvarine (verrijkt)", 5)],
            .eveningSnack: [("Ei (gekookt)", 105), ("Kipfilet (beleg)", 55)],
        ],
        [
            .breakfast: [("Volkorenbrood", 115), ("Pindakaas (100% pinda)", 20), ("Banaan", 110), ("Halfvolle melk", 325), ("Magere kwark", 160)],
            .lunch: [("Magere kwark", 325), ("Muesli zonder suiker", 55), ("Appel", 160), ("Rijstwafel", 20), ("Pindakaas (100% pinda)", 15)],
            .snack: [("Volkorenbrood", 75), ("Kaas 30+", 30), ("Halfvolle melk", 270)],
            .dinner: [("Aardappel (gekookt)", 325), ("Zuurkool", 215), ("Rundergehakt 5% (gebakken)", 160), ("Halvarine (verrijkt)", 5)],
            .eveningSnack: [("Hüttenkäse", 215), ("Komkommer", 110)],
        ],
        [
            .breakfast: [("Havermout", 75), ("Halfvolle melk", 330), ("Magere kwark", 165), ("Banaan", 110), ("Pindakaas (100% pinda)", 10)],
            .lunch: [("Volkorenbrood", 155), ("Tonijn in water (blik)", 130), ("Magere yoghurt", 55), ("Ui", 35), ("Komkommer", 110), ("Tomaat", 110), ("Banaan", 110)],
            .snack: [("Rijstwafel", 35), ("Hüttenkäse", 165), ("Tomaat", 110)],
            .dinner: [("Aardappel (gekookt)", 275), ("Wortel", 275), ("Ui", 110), ("Rundergehakt 5% (gebakken)", 165), ("Halvarine (verrijkt)", 5)],
            .eveningSnack: [("Magere kwark", 275), ("Havermout", 20)],
        ],
        [
            .breakfast: [("Magere yoghurt", 355), ("Magere kwark", 175), ("Muesli zonder suiker", 70), ("Banaan", 120)],
            .lunch: [("Volkoren wrap", 140), ("Rundergehakt 5% (gebakken)", 120), ("IJsbergsla", 60), ("Tomaat", 120), ("Magere yoghurt", 60)],
            .snack: [("Ei (gekookt)", 120), ("Kipfilet (beleg)", 60), ("Appel", 175)],
            .dinner: [("Witte pasta (gekookt)", 260), ("Tonijn in water (blik)", 175), ("Tomaat", 235), ("Ui", 60), ("Olijfolie", 10)],
            .eveningSnack: [("Magere yoghurt", 235), ("Magere kwark", 175), ("Blauwe bessen", 60)],
        ],
        [
            .breakfast: [("Volkorenbrood", 110), ("Ei (gekookt)", 105), ("Halfvolle melk", 105), ("Magere kwark", 210), ("Aardbeien", 105)],
            .lunch: [("Ei (gekookt)", 155), ("Eiwit van ei", 105), ("Ui", 50), ("Rode paprika", 105), ("Volkorenbrood", 75), ("Kaas 30+", 20)],
            .snack: [("Halfvolle melk", 420), ("Banaan", 105), ("Pinda's (ongezouten)", 15)],
            .dinner: [("Witte pasta (gekookt)", 230), ("Rundergehakt 5% (gebakken)", 155), ("Tomaat", 210), ("Ui", 80), ("Wortel", 105), ("Olijfolie", 5)],
            .eveningSnack: [("Volkorenbrood", 35), ("Hüttenkäse", 155)],
        ],
        [
            .breakfast: [("Magere kwark", 425), ("Havermout", 55), ("Appel", 160), ("Pindakaas (100% pinda)", 10)],
            .lunch: [("Witte pasta (gekookt)", 215), ("Kipfilet (gebakken)", 105), ("Rode paprika", 105), ("Doperwten", 80), ("Olijfolie", 5)],
            .snack: [("Magere kwark", 215), ("Pinda's (ongezouten)", 20), ("Mandarijn", 160)],
            .dinner: [("Kidneybonen (gekookt)", 215), ("Rundergehakt 5% (gebakken)", 135), ("Tomaat", 215), ("Ui", 80), ("Rode paprika", 105), ("Witte rijst (gekookt)", 160)],
            .eveningSnack: [("Ei (gekookt)", 105), ("Kipfilet (beleg)", 55)],
        ],
    ]

    /// Budget menu shopping list, sorted by name.
    static let budgetShopping: [ShoppingReference] = [
        .init(name: "Aardappel (gekookt)", grams: 920, aisle: "Groente & fruit", label: "1 zak aardappels (2 kg)", cost: 2.4, used: 1.104),
        .init(name: "Aardbeien", grams: 105, aisle: "Diepvries", label: "1 zak (500 g)", cost: 2.75, used: 0.5775),
        .init(name: "Appel", grams: 750, aisle: "Groente & fruit", label: "5 appels", cost: 1.875, used: 1.875),
        .init(name: "Banaan", grams: 675, aisle: "Groente & fruit", label: "6 bananen", cost: 1.368, used: 1.2825),
        .init(name: "Blauwe bessen", grams: 60, aisle: "Diepvries", label: "1 zak (500 g)", cost: 3.5, used: 0.42),
        .init(name: "Broccoli", grams: 155, aisle: "Groente & fruit", label: "1 broccoli", cost: 1.5, used: 0.465),
        .init(name: "Bruine bonen (gekookt)", grams: 210, aisle: "Conserven & peulvruchten", label: "1 pot (400 g uitgelekt)", cost: 0.88, used: 0.462),
        .init(name: "Doperwten", grams: 80, aisle: "Diepvries", label: "1 zak (750 g)", cost: 1.875, used: 0.2),
        .init(name: "Ei (gekookt)", grams: 900, aisle: "Zuivel & eieren", label: "2 dozen (10 eieren)", cost: 6, used: 5.4),
        .init(name: "Eiwit van ei", grams: 105, aisle: "Zuivel & eieren", label: "1 pak (500 g)", cost: 2.5, used: 0.525),
        .init(name: "Halfvolle melk", grams: 1715, aisle: "Zuivel & eieren", label: "2 pakken (1 L)", cost: 2.3, used: 1.9723),
        .init(name: "Halvarine (verrijkt)", grams: 30, aisle: "Zuivel & eieren", label: "1 kuipje (500 g)", cost: 2, used: 0.12),
        .init(name: "Havermout", grams: 150, aisle: "Ontbijt & beleg", label: "1 zak (1 kg)", cost: 2, used: 0.3),
        .init(name: "Hüttenkäse", grams: 635, aisle: "Zuivel & eieren", label: "4 bakjes (200 g)", cost: 4.4, used: 3.4925),
        .init(name: "IJsbergsla", grams: 60, aisle: "Groente & fruit", label: "1 krop", cost: 1, used: 0.15),
        .init(name: "Kaas 30+", grams: 90, aisle: "Kaas & vleeswaren", label: "1 stuk (500 g)", cost: 5.5, used: 0.99),
        .init(name: "Kidneybonen (gekookt)", grams: 215, aisle: "Conserven & peulvruchten", label: "1 pot/blik (250 g uitgelekt)", cost: 0.55, used: 0.473),
        .init(name: "Kipdij (gebakken)", grams: 185, aisle: "Vlees & vis", label: "1 pak rauw (500 g)", cost: 4.125, used: 2.035),
        .init(name: "Kipfilet (beleg)", grams: 350, aisle: "Kaas & vleeswaren", label: "3 pakjes (150 g)", cost: 5.4, used: 4.2),
        .init(name: "Kipfilet (gebakken)", grams: 285, aisle: "Vlees & vis", label: "1 pak rauw (500 g)", cost: 4.5, used: 3.42),
        .init(name: "Komkommer", grams: 530, aisle: "Groente & fruit", label: "2 komkommers", cost: 1.76, used: 1.166),
        .init(name: "Magere kwark", grams: 2845, aisle: "Zuivel & eieren", label: "3 emmers (1 kg)", cost: 7.8, used: 7.397),
        .init(name: "Magere yoghurt", grams: 705, aisle: "Zuivel & eieren", label: "1 pak (1 L)", cost: 1.4, used: 0.987),
        .init(name: "Mandarijn", grams: 320, aisle: "Groente & fruit", label: "5 mandarijnen", cost: 0.875, used: 0.8),
        .init(name: "Muesli zonder suiker", grams: 125, aisle: "Ontbijt & beleg", label: "1 pak (750 g)", cost: 3.375, used: 0.5625),
        .init(name: "Olijfolie", grams: 35, aisle: "Olie & sauzen", label: "1 fles (500 ml)", cost: 4.14, used: 0.315),
        .init(name: "Pinda's (ongezouten)", grams: 55, aisle: "Noten & snacks", label: "1 zak (500 g)", cost: 2.5, used: 0.275),
        .init(name: "Pindakaas (100% pinda)", grams: 65, aisle: "Ontbijt & beleg", label: "1 pot (350 g)", cost: 2.8, used: 0.52),
        .init(name: "Rijstwafel", grams: 55, aisle: "Brood", label: "1 pak (130 g)", cost: 0.78, used: 0.33),
        .init(name: "Rode paprika", grams: 315, aisle: "Groente & fruit", label: "3 paprika's", cost: 2.025, used: 1.4175),
        .init(name: "Rundergehakt 5% (gebakken)", grams: 735, aisle: "Vlees & vis", label: "2 pakken rauw (500 g)", cost: 10.5, used: 10.29),
        .init(name: "Sojasaus", grams: 10, aisle: "Olie & sauzen", label: "1 fles (150 ml)", cost: 0.75, used: 0.05),
        .init(name: "Sperziebonen", grams: 265, aisle: "Diepvries", label: "1 zak (750 g)", cost: 3, used: 1.06),
        .init(name: "Tomaat", grams: 1205, aisle: "Groente & fruit", label: "3 bakken (500 g)", cost: 4.5, used: 3.615),
        .init(name: "Tonijn in water (blik)", grams: 305, aisle: "Conserven & peulvruchten", label: "3 blikken tonijn", cost: 4.032, used: 3.66),
        .init(name: "Ui", grams: 445, aisle: "Groente & fruit", label: "1 net uien (1 kg)", cost: 1.3, used: 0.5785),
        .init(name: "Volkoren wrap", grams: 140, aisle: "Brood", label: "1 pak wraps (6 st.)", cost: 1.85, used: 0.7),
        .init(name: "Volkorenbrood", grams: 1035, aisle: "Brood", label: "2 broden (800 g)", cost: 4.16, used: 2.691),
        .init(name: "Witte pasta (gekookt)", grams: 705, aisle: "Pasta, rijst & granen", label: "1 pak (500 g)", cost: 0.92, used: 0.564),
        .init(name: "Witte rijst (gekookt)", grams: 415, aisle: "Pasta, rijst & granen", label: "1 zak rijst (1 kg)", cost: 2.1, used: 0.3112),
        .init(name: "Wortel", grams: 480, aisle: "Groente & fruit", label: "1 zak (1 kg)", cost: 1.2, used: 0.576),
        .init(name: "Zuurkool", grams: 215, aisle: "Groente & fruit", label: "1 zak (500 g)", cost: 1, used: 0.43),
    ]
    static let budgetCheckout = 119.19
    static let budgetEaten = 67.7595
    static let budgetStores: [(name: String, checkout: Double, eaten: Double)] = [
        ("Dirk", 108.4629, 61.6611),
        ("Lidl", 112.0386, 63.6939),
        ("ALDI", 113.2305, 64.3715),
        ("Albert Heijn", 119.19, 67.7595),
        ("Jumbo", 120.3819, 68.4371),
    ]
    static let budgetAisles: [String] = ["Groente & fruit", "Brood", "Ontbijt & beleg", "Zuivel & eieren", "Kaas & vleeswaren", "Vlees & vis", "Pasta, rijst & granen", "Conserven & peulvruchten", "Diepvries", "Noten & snacks", "Olie & sauzen"]
    static let variedCheckout = 243.127
    static let variedEaten = 98.1665
    static let variedRowCount = 80
}
