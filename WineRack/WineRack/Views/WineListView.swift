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
        // Eén keer filteren en groeperen per keer dat het scherm wordt opgebouwd.
        let content = ListContent(wines: wines.filter { matchesFilters($0) })

        return List {
            Section {
                Picker("Locatie", selection: $filter) {
                    ForEach(LocationFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                LabeledContent("Totaal", value: bottlesText(content.totalBottles))
            }

            ForEach(content.groups, id: \.status) { group in
                Section {
                    ForEach(group.wines) { wine in row(for: wine) }
                } header: {
                    Label(group.status.title, systemImage: group.status.icon)
                        .foregroundStyle(group.status.color)
                }
            }

            if !content.finished.isEmpty {
                Section("Op") {
                    ForEach(content.finished) { wine in row(for: wine) }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Naam, druif, regio of gerecht")
        .overlay {
            if content.isEmpty && !searchText.isEmpty {
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

    private func matchesFilters(_ wine: Wine) -> Bool {
        if let location = filter.location, wine.location != location { return false }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        let fields = [wine.name, wine.producer, wine.grape, wine.region] + wine.pairings
        return fields.contains { $0.localizedStandardContains(query) }
    }

    private func bottlesText(_ count: Int) -> String {
        count == 1 ? "1 fles" : "\(count) flessen"
    }
}

// De gefilterde wijnen, verdeeld over de secties van de lijst.
private struct ListContent {
    struct StatusGroup {
        let status: DrinkStatus
        let wines: [Wine]
    }

    let groups: [StatusGroup]
    let finished: [Wine]
    let totalBottles: Int
    let isEmpty: Bool

    init(wines: [Wine]) {
        let year = DrinkStatus.currentYear
        let inStock = wines.filter { $0.quantity > 0 }
        // Per drinkstatus; binnen een groep op "drinken vóór" (onbekend achteraan).
        let byStatus = Dictionary(grouping: inStock) {
            DrinkStatus(drinkFrom: $0.drinkFrom, drinkBy: $0.drinkBy, year: year)
        }
        groups = DrinkStatus.allCases.compactMap { status in
            guard let items = byStatus[status] else { return nil }
            let sorted = items.sorted { ($0.drinkBy ?? Int.max) < ($1.drinkBy ?? Int.max) }
            return StatusGroup(status: status, wines: sorted)
        }
        finished = wines.filter { $0.quantity == 0 }
        totalBottles = wines.reduce(0) { $0 + $1.quantity }
        isEmpty = wines.isEmpty
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
