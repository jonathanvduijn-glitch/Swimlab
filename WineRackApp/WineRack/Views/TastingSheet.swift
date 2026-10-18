import SwiftUI
import SwiftData

// "Fles gedronken": legt vast wanneer en waarbij, en haalt één fles van de voorraad.
struct TastingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let wine: Wine

    @State private var date = Date.now
    @State private var dish = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(wine.displayName)
                        .font(.headline)
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                }
                Section("Gerecht") {
                    TextField("Wat at je erbij?", text: $dish)
                    if !wine.pairings.isEmpty {
                        quickDishes
                    }
                }
                Section("Notitie") {
                    TextField("Hoe was hij?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Fles gedronken")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") { save() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // Snelkeuzeknoppen met de gerechten van deze wijn.
    private var quickDishes: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(wine.pairings, id: \.self) { pairing in
                    Button(pairing) { dish = pairing }
                        .buttonStyle(.bordered)
                        .tint(dish == pairing ? Color.accentColor : Color.secondary)
                }
            }
        }
    }

    // Tasting opslaan en het aantal met 1 verlagen (niet onder 0).
    private func save() {
        let tasting = Tasting(
            date: date,
            dish: dish.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(tasting)
        tasting.wine = wine
        wine.quantity = max(0, wine.quantity - 1)
        dismiss()
    }
}

#Preview {
    TastingSheet(wine: PreviewData.sampleWine)
        .modelContainer(PreviewData.container)
}
