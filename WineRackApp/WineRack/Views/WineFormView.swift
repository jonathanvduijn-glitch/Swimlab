import SwiftUI

// Formulier voor een wijn; gebruikt bij "toevoegen" én bij "Wijzig".
struct WineFormView: View {
    let title: String
    let onCancel: () -> Void
    let onSave: (WineDraft) -> Void

    @State private var draft: WineDraft

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
            TextListSection(title: "Past bij", placeholder: "Gerecht toevoegen", items: $draft.pairings)
            TextListSection(title: "Aroma's", placeholder: "Smaak toevoegen, bijv. kers", items: $draft.aromas)
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
}

// Lijst met losse woorden (gerechten of aroma's): toevoegen en met vegen verwijderen.
struct TextListSection: View {
    let title: String
    let placeholder: String
    @Binding var items: [String]
    @State private var newItem = ""

    var body: some View {
        Section {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
            .onDelete { offsets in
                items.remove(atOffsets: offsets)
            }
            HStack {
                TextField(placeholder, text: $newItem)
                    .onSubmit { addItem() }
                Button("Voeg toe") { addItem() }
                    .buttonStyle(.borderless)
                    .disabled(trimmed.isEmpty)
            }
        } header: {
            Text(title)
        } footer: {
            Text("Veeg naar links over een regel om die te verwijderen.")
        }
    }

    private var trimmed: String {
        newItem.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addItem() {
        let item = trimmed
        guard !item.isEmpty, !items.contains(item) else { return }
        items.append(item)
        newItem = ""
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
