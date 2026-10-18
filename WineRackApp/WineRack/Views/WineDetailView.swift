import SwiftUI
import SwiftData

// Detailscherm van één wijn. Aantal, locatie en sterren worden direct opgeslagen.
struct WineDetailView: View {
    @Bindable var wine: Wine

    @State private var showingEdit = false
    @State private var showingTasting = false

    var body: some View {
        List {
            labelSection
            statusSection
            stockSection
            detailsSection
            Section("Beoordeling") {
                StarRatingView(rating: $wine.rating)
            }
            if !wine.pairings.isEmpty {
                Section("Past bij") {
                    ForEach(wine.pairings, id: \.self) { dish in
                        Label(dish, systemImage: "fork.knife")
                    }
                }
            }
            if !wine.aromas.isEmpty {
                Section("Aroma's") {
                    AromaTags(aromas: wine.aromas)
                }
            }
            if !wine.notes.isEmpty {
                Section("Notities") {
                    Text(wine.notes)
                }
            }
            historySection
        }
        .navigationTitle(wine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Wijzig") { showingEdit = true }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                WineFormView(
                    title: "Wijzig wijn",
                    draft: WineDraft(wine: wine),
                    onCancel: { showingEdit = false },
                    onSave: { draft in
                        draft.apply(to: wine)
                        showingEdit = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingTasting) {
            TastingSheet(wine: wine)
        }
    }

    // Grote etiketfoto.
    @ViewBuilder
    private var labelSection: some View {
        if let data = wine.labelImage, let image = UIImage(data: data) {
            Section {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 360)
            }
        }
    }

    // Drinkstatus en drinkperiode.
    private var statusSection: some View {
        Section("Drinkstatus") {
            HStack {
                Label(wine.drinkStatus.title, systemImage: wine.drinkStatus.icon)
                    .foregroundStyle(wine.drinkStatus.color)
                Spacer()
                Text(wine.drinkWindowText ?? "Geen periode")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // Aantal, locatie en de knop "Fles gedronken".
    private var stockSection: some View {
        Section("Voorraad") {
            Stepper(bottlesText, value: $wine.quantity, in: 0...999)
            Picker("Locatie", selection: $wine.location) {
                ForEach(WineLocation.allCases) { location in
                    Label(location.rawValue, systemImage: location.icon).tag(location)
                }
            }
            Button { showingTasting = true } label: {
                Label("Fles gedronken", systemImage: "wineglass")
            }
            .disabled(wine.quantity == 0)
        }
    }

    private var bottlesText: String {
        wine.quantity == 1 ? "1 fles" : "\(wine.quantity) flessen"
    }

    // Wijngegevens (alleen ingevulde velden).
    private var detailsSection: some View {
        Section("Wijn") {
            detailRow("Producent", wine.producer)
            detailRow("Jaargang", wine.vintage.map { String($0) } ?? "")
            detailRow("Druif", wine.grape)
            detailRow("Regio", wine.region)
            detailRow("Land", wine.country)
            detailRow("Type", wine.type.rawValue)
        }
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String) -> some View {
        if !value.isEmpty {
            LabeledContent(label, value: value)
        }
    }

    // Geschiedenis van gedronken flessen, nieuwste eerst.
    private var historySection: some View {
        Section("Gedronken") {
            let tastings = (wine.tastings ?? []).sorted { $0.date > $1.date }
            if tastings.isEmpty {
                Text("Nog geen flessen gedronken.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tastings) { tasting in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tasting.date, format: .dateTime.day().month(.wide).year())
                            .font(.headline)
                        if !tasting.dish.isEmpty {
                            Label(tasting.dish, systemImage: "fork.knife")
                        }
                        if !tasting.note.isEmpty {
                            Text(tasting.note)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

// Aroma's als kleine labeltjes naast elkaar.
struct AromaTags: View {
    let aromas: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(aromas, id: \.self) { aroma in
                    Text(aroma)
                        .font(.subheadline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WineDetailView(wine: PreviewData.sampleWine)
    }
    .modelContainer(PreviewData.container)
}
