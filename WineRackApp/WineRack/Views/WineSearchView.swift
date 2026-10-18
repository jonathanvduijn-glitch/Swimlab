import SwiftUI

// Wijn zoeken op naam: Claude geeft de wijnen die het best passen,
// en een tik op een treffer vult het formulier.
struct WineSearchView: View {
    let onSelect: (LabelScanResult) -> Void

    @State private var query = ""
    @State private var results: [LabelScanResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @FocusState private var fieldFocused: Bool

    var body: some View {
        List {
            Section {
                TextField("Bijv. Barolo Conterno 2016", text: $query)
                    .focused($fieldFocused)
                    .submitLabel(.search)
                    .onSubmit { startSearch() }
                    .autocorrectionDisabled()
                Button { startSearch() } label: {
                    Label("Zoek", systemImage: "magnifyingglass")
                }
                .disabled(trimmedQuery.isEmpty || isSearching)
            } footer: {
                Text("Claude zoekt in zijn eigen kennis van wijnen. Controleer daarna altijd het formulier.")
            }

            if isSearching {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Claude zoekt de wijn…")
                        Spacer()
                    }
                }
            } else if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            } else if !results.isEmpty {
                resultsSection
            }
        }
        .navigationTitle("Zoek op naam")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fieldFocused = true }
    }

    // De gevonden wijnen; tik om te kiezen.
    private var resultsSection: some View {
        Section("Gevonden") {
            ForEach(Array(results.enumerated()), id: \.offset) { _, wine in
                Button { onSelect(wine) } label: {
                    resultRow(wine)
                }
                .tint(.primary)
            }
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
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Zoekopdracht naar Claude sturen.
    private func startSearch() {
        let text = trimmedQuery
        guard !text.isEmpty, !isSearching else { return }
        fieldFocused = false
        Task { await search(text) }
    }

    private func search(_ text: String) async {
        isSearching = true
        errorMessage = nil
        results = []
        defer { isSearching = false }
        do {
            results = try await ClaudeService.searchWines(query: text)
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
