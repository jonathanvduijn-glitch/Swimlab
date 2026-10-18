import SwiftUI
import SwiftData

// Hoofdscherm "Wine Rack": alle wijnen, gegroepeerd op drinkstatus.
struct WineListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Wine.name) private var wines: [Wine]

    @State private var filter: LocationFilter = .all
    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var wineToDrink: Wine?

    var body: some View {
        NavigationStack {
            Group {
                if wines.isEmpty {
                    ContentUnavailableView(
                        "Nog geen wijnen",
                        systemImage: "wineglass",
                        description: Text("Tik op + om je eerste etiket te scannen.")
                    )
                } else {
                    wineList
                }
            }
            .navigationTitle("Wine Rack")
            .navigationDestination(for: Wine.self) { wine in
                WineDetailView(wine: wine)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Instellingen")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Wijn toevoegen")
                }
            }
            .sheet(isPresented: $showingAdd) { AddWineView() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(item: $wineToDrink) { wine in TastingSheet(wine: wine) }
        }
    }

    // De lijst met filter, groepen en de sectie "Op".
    private var wineList: some View {
        List {
            Section {
                Picker("Locatie", selection: $filter) {
                    ForEach(LocationFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                LabeledContent("Totaal", value: bottlesText(totalBottles))
            }

            ForEach(groups, id: \.status) { group in
                Section {
                    ForEach(group.wines) { wine in row(for: wine) }
                } header: {
                    Label(group.status.title, systemImage: group.status.icon)
                        .foregroundStyle(group.status.color)
                }
            }

            if !finishedWines.isEmpty {
                Section("Op") {
                    ForEach(finishedWines) { wine in row(for: wine) }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Naam, druif, regio of gerecht")
        .overlay {
            if filteredWines.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    // Eén rij met veegacties.
    private func row(for wine: Wine) -> some View {
        NavigationLink(value: wine) {
            WineRowView(wine: wine)
        }
        .swipeActions(edge: .leading) {
            if wine.quantity > 0 {
                Button { wineToDrink = wine } label: {
                    Label("Gedronken", systemImage: "wineglass")
                }
                .tint(.green)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { context.delete(wine) } label: {
                Label("Verwijder", systemImage: "trash")
            }
        }
    }

    // MARK: - Filteren en groeperen

    private struct WineGroup {
        let status: DrinkStatus
        let wines: [Wine]
    }

    private var filteredWines: [Wine] {
        wines.filter { wine in
            (filter.location == nil || wine.location == filter.location) && matchesSearch(wine)
        }
    }

    private func matchesSearch(_ wine: Wine) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        let fields = [wine.name, wine.producer, wine.grape, wine.region] + wine.pairings
        return fields.contains { $0.localizedStandardContains(query) }
    }

    // Wijnen met flessen, per drinkstatus; binnen een groep op "drinken vóór".
    private var groups: [WineGroup] {
        let inStock = filteredWines.filter { $0.quantity > 0 }
        return DrinkStatus.allCases.compactMap { status in
            let items = inStock
                .filter { $0.drinkStatus == status }
                .sorted { ($0.drinkBy ?? Int.max) < ($1.drinkBy ?? Int.max) }
            return items.isEmpty ? nil : WineGroup(status: status, wines: items)
        }
    }

    // Wijnen waarvan alle flessen op zijn.
    private var finishedWines: [Wine] {
        filteredWines.filter { $0.quantity == 0 }
    }

    private var totalBottles: Int {
        filteredWines.reduce(0) { $0 + $1.quantity }
    }

    private func bottlesText(_ count: Int) -> String {
        count == 1 ? "1 fles" : "\(count) flessen"
    }
}

#Preview("Met wijnen") {
    WineListView()
        .modelContainer(PreviewData.container)
}

#Preview("Leeg") {
    WineListView()
        .modelContainer(for: [Wine.self, Tasting.self], inMemory: true)
}
