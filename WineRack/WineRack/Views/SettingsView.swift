import SwiftUI

// Instellingen: de Claude API-sleutel invullen en zien welk model wordt gebruikt.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey = ""
    @State private var hasKey = false
    @State private var message: String?
    @State private var messageIsError = false

    var body: some View {
        NavigationStack {
            Form {
                keySection
                Section("Status") {
                    LabeledContent("Sleutel", value: hasKey ? "Opgeslagen" : "Nog niet ingevuld")
                    if hasKey {
                        Button("Verwijder sleutel", role: .destructive) { deleteKey() }
                    }
                }
                Section("Model") {
                    LabeledContent("Claude-model", value: ClaudeConfig.model)
                }
            }
            .navigationTitle("Instellingen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klaar") { dismiss() }
                }
            }
            .onAppear { hasKey = KeychainService.loadAPIKey() != nil }
        }
    }

    // Invoerveld, bewaarknop, bevestiging en uitleg.
    private var keySection: some View {
        Section {
            SecureField("sk-ant-…", text: $apiKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Bewaar sleutel") { saveKey() }
                .disabled(trimmedKey.isEmpty)
            if let message {
                Label(message, systemImage: messageIsError ? "xmark.octagon.fill" : "checkmark.circle.fill")
                    .foregroundStyle(messageIsError ? Color.red : Color.green)
            }
        } header: {
            Text("Claude API-sleutel")
        } footer: {
            Text("Je sleutel wordt versleuteld bewaard in de Keychain van dit toestel. Hij staat nergens anders en wordt alleen naar Anthropic gestuurd om etiketten te lezen.")
        }
    }

    private var trimmedKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveKey() {
        if KeychainService.saveAPIKey(trimmedKey) {
            apiKey = ""
            hasKey = true
            messageIsError = false
            message = "Sleutel bewaard."
        } else {
            messageIsError = true
            message = "Bewaren is niet gelukt. Probeer het opnieuw."
        }
    }

    private func deleteKey() {
        KeychainService.deleteAPIKey()
        hasKey = false
        messageIsError = false
        message = "Sleutel verwijderd."
    }
}

#Preview {
    SettingsView()
}
