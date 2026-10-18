import SwiftUI
import SwiftData

// Startpunt van de app: toont de hoofdlijst en maakt de SwiftData-opslag aan.
@main
struct WineRackApp: App {
    var body: some Scene {
        WindowGroup {
            WineListView()
                // Datums altijd in het Nederlands tonen.
                .environment(\.locale, Locale(identifier: "nl_NL"))
        }
        .modelContainer(for: [Wine.self, Tasting.self])
    }
}
