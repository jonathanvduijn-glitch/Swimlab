import SwiftUI

// Formulier voor een wijn; gebruikt bij "toevoegen" én bij "Wijzig".
struct WineFormView: View {
    let title: String
    let onCancel: () -> Void
    let onSave: (WineDraft) -> Void

    @State private var draft: WineDraft
    @State private var newPairing = ""

    init(title: String, draft: WineDraft, onCancel: @escaping () -> Void, onSave: @escaping (WineDraft) -> Void) {
        self.title = title
        self.onCancel = onCancel
        self.onSave = onSave
        _draft = State(initialValue: draft)
    }

    var body: some View {
        Form {
            photoSection
            wineSection
            Section("Voorraad") {
                Stepper("Aantal flessen: \(draft.quantity)", value: $draft.quantity, in: 0...999)
                Picker("Locatie", selection: $draft.location) {
                    ForEach(WineLocation.allCases) { location in
                        Text(location.rawValue).tag(location)
                    }
                }
            }
            Section {
                YearField(title: "Vanaf", year: $draft.drinkFrom)
                YearField(title: "Vóór", year: $draft.drinkBy)
            } header: {
                Text("Drinkperiode")
            } footer: {
                if let problem = draft.yearProblem {
                    Text(problem).foregroundStyle(.red)
                }
            }
            pairingsSection
            Section("Beoordeling") {
                StarRatingView(rating: $draft.rating)
            }
            Section("Notities") {
                TextField("Smaak, aankoop, cadeau van…", text: $draft.notes, axis: .vertical)
                    .lineLimit(3...8)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuleer") { onCancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Bewaar") { onSave(draft) }
                    .disabled(!draft.canSave)
            }
        }
    }

    // Etiketfoto (als die er is).
    @ViewBuilder
    private var photoSection: some View {
        if let data = draft.imageData, let image = UIImage(data: data) {
            Section {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 220)
            }
        }
    }

    // Gegevens van de wijn.
    private var wineSection: some View {
        Section("Wijn") {
            TextField("Naam (verplicht)", text: $draft.name)
            TextField("Producent", text: $draft.producer)
            YearField(title: "Jaargang", year: $draft.vintage)
            TextField("Druif", text: $draft.grape)
            TextField("Regio", text: $draft.region)
            TextField("Land", text: $draft.country)
            Picker("Type", selection: $draft.type) {
                ForEach(WineType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
        }
    }

    // Gerechten toevoegen en (met vegen) verwijderen.
    private var pairingsSection: some View {
        Section {
            ForEach(draft.pairings, id: \.self) { dish in
                Text(dish)
            }
            .onDelete { offsets in
                draft.pairings.remove(atOffsets: offsets)
            }
            HStack {
                TextField("Gerecht toevoegen", text: $newPairing)
                    .onSubmit { addPairing() }
                Button("Voeg toe") { addPairing() }
                    .buttonStyle(.borderless)
                    .disabled(trimmedPairing.isEmpty)
            }
        } header: {
            Text("Past bij")
        } footer: {
            Text("Veeg naar links over een gerecht om het te verwijderen.")
        }
    }

    private var trimmedPairing: String {
        newPairing.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addPairing() {
        let dish = trimmedPairing
        guard !dish.isEmpty, !draft.pairings.contains(dish) else { return }
        draft.pairings.append(dish)
        newPairing = ""
    }
}

// Invoerveld voor een jaartal (mag leeg blijven).
struct YearField: View {
    let title: String
    @Binding var year: Int?

    var body: some View {
        LabeledContent(title) {
            TextField("jaar", text: yearText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
        }
    }

    // Zet het getal om naar tekst en terug; alleen cijfers tellen mee.
    private var yearText: Binding<String> {
        Binding(
            get: { year.map { String($0) } ?? "" },
            set: { newValue in
                let digits = String(newValue.filter(\.isASCII).filter(\.isNumber).prefix(4))
                year = Int(digits)
            }
        )
    }
}

#Preview {
    NavigationStack {
        WineFormView(
            title: "Nieuwe wijn",
            draft: WineDraft(wine: PreviewData.sampleWine),
            onCancel: {},
            onSave: { _ in }
        )
    }
    .modelContainer(PreviewData.container)
}
