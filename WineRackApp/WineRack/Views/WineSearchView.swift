import SwiftUI

// Wijn zoeken op naam. Eerst snel in Claude's eigen kennis; staat de wijn er niet bij,
// dan kan Claude op internet zoeken. Een tik op een treffer vult het formulier.
struct WineSearchView: View {
    // Zoekterm die al is ingevuld (bijv. vanuit de zoekbalk van het hoofdscherm); zoekt dan direct.
    let initialQuery: String
    let onSelect: (LabelScanResult) -> Void

    @State private var query = ""
    @State private var results: [LabelScanResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    // De laatst gezochte term en of daarbij al op internet is gezocht.
    @State private var lastQuery: String?
    @State private var searchedOnInternet = false
    @FocusState private var fieldFocused: Bool

    init(initialQuery: String = "", onSelect: @escaping (LabelScanResult) -> Void) {
        self.initialQuery = initialQuery
        self.onSelect = onSelect
    }

    var body: some View {
        List {
            Section {
                TextField("Bijv. Barolo Conterno 2016", text: $query)
                    .focused($fieldFocused)
                    .submitLabel(.search)
                    .onSubmit { startSearch(onInternet: false) }
                    .autocorrectionDisabled()
                Button { startSearch(onInternet: false) } label: {
                    Label("Zoek", systemImage: "magnifyingglass")
                }
                .disabled(trimmedQuery.isEmpty || isSearching)
            } footer: {
                Text("Claude zoekt eerst in zijn eigen kennis. Niet gevonden? Laat Claude dan op internet zoeken. Controleer daarna altijd het formulier.")
            }

            if isSearching {
                progressSection
            } else {
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
                if !results.isEmpty {
                    resultsSection
                }
                if lastQuery != nil && !searchedOnInternet {
                    internetSection
                }
            }
        }
        .navigationTitle("Zoek op naam")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: startInitialSearch)
    }

    // Meegegeven zoekterm direct zoeken; anders het invoerveld klaarzetten.
    private func startInitialSearch() {
        let text = initialQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard lastQuery == nil else { return }
        if text.isEmpty {
            fieldFocused = true
        } else {
            query = text
            startSearch(onInternet: false)
        }
    }

    // Wachten op Claude.
    private var progressSection: some View {
        Section {
            HStack {
                Spacer()
                ProgressView(progressText)
                Spacer()
            }
        }
    }

    // De gevonden wijnen; tik om te kiezen.
    private var resultsSection: some View {
        Section(resultsTitle) {
            ForEach(Array(results.enumerated()), id: \.offset) { _, wine in
                Button { onSelect(wine) } label: {
                    resultRow(wine)
                }
                .tint(.primary)
            }
        }
    }

    // Knop om alsnog op internet te zoeken.
    private var internetSection: some View {
        Section {
            Button { startSearch(onInternet: true) } label: {
                Label("Niet de goede wijn? Zoek op internet", systemImage: "globe")
            }
        } footer: {
            Text("Zoeken op internet duurt wat langer en kost een paar cent per keer.")
        }
    }

    private func resultRow(_ wine: LabelScanResult) -> some View {
        let type = WineType.from(wine.type) ?? .other
        return HStack(spacing: 12) {
            WineThumbnail(imageData: nil, type: type, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: wine.vintage.map { "\(wine.name) \($0)" } ?? wine.name)
                    .font(.headline)
                let details = [wine.producer, wine.region, wine.country].filter { !$0.isEmpty }
                if !details.isEmpty {
                    Text(details.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !wine.aromas.isEmpty {
                    Text(wine.aromas.prefix(4).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
    }

    private var progressText: String {
        searchedOnInternet ? "Claude zoekt op internet… (dit kan even duren)" : "Claude zoekt de wijn…"
    }

    private var resultsTitle: String {
        searchedOnInternet ? "Gevonden op internet" : "Gevonden"
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Zoekopdracht starten. Op internet zoeken gebeurt met de laatst gezochte term.
    private func startSearch(onInternet: Bool) {
        let text = onInternet ? (lastQuery ?? trimmedQuery) : trimmedQuery
        guard !text.isEmpty, !isSearching else { return }
        fieldFocused = false
        lastQuery = text
        searchedOnInternet = onInternet
        Task { await search(text, onInternet: onInternet) }
    }

    private func search(_ text: String, onInternet: Bool) async {
        isSearching = true
        errorMessage = nil
        results = []
        defer { isSearching = false }
        do {
            results = try await ClaudeService.searchWines(query: text, onInternet: onInternet)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        WineSearchView { _ in }
    }
}
