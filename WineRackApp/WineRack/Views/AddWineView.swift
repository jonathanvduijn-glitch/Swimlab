import SwiftUI
import SwiftData
import PhotosUI

// Nieuwe wijn: eerst een foto maken of kiezen, Claude leest het etiket,
// daarna controleer je alles in het formulier.
struct AddWineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var pickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var isScanning = false
    @State private var photoData: Data?
    @State private var errorMessage: String?
    @State private var draft: WineDraft?

    var body: some View {
        NavigationStack {
            if let draft {
                WineFormView(title: "Nieuwe wijn", draft: draft, onCancel: { dismiss() }, onSave: { save($0) })
            } else {
                photoStep
            }
        }
    }

    // Stap 1: foto kiezen of maken.
    private var photoStep: some View {
        VStack(spacing: 16) {
            Spacer()
            if isScanning {
                ProgressView("Claude leest het etiket…")
                    .controlSize(.large)
            } else {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 72))
                    .foregroundStyle(.secondary)
                Text("Scan het etiket")
                    .font(.title2.bold())
                Text("Maak een foto of kies er een. Claude vult daarna het formulier voor je in.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                if let errorMessage {
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.red)
                }
                photoButtons
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Wijn toevoegen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuleer") { dismiss() }
            }
        }
        .onChange(of: pickerItem) { _, item in
            Task { await loadPickedPhoto(item) }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                Task { await scan(image) }
            }
            .ignoresSafeArea()
        }
    }

    private var photoButtons: some View {
        VStack(spacing: 12) {
            if CameraPicker.isAvailable {
                Button { showingCamera = true } label: {
                    Label("Maak foto", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Kies foto", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            Button("Zelf invullen") {
                var manual = WineDraft()
                manual.imageData = photoData
                draft = manual
            }
        }
        .controlSize(.large)
        .padding(.top)
    }

    // Foto uit de fotobibliotheek laden.
    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        pickerItem = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Deze foto kon niet worden geopend."
                return
            }
            await scan(image)
        } catch {
            errorMessage = "Deze foto kon niet worden geopend."
        }
    }

    // Foto verkleinen, naar Claude sturen en het formulier vooraf invullen.
    private func scan(_ image: UIImage) async {
        errorMessage = nil
        isScanning = true
        defer { isScanning = false }

        let prepared = await ImageResizer.prepareForScan(image)
        photoData = prepared.stored
        guard let upload = prepared.upload else {
            errorMessage = "Deze foto kon niet worden verwerkt."
            return
        }

        do {
            let result = try await ClaudeService.scanLabel(jpegData: upload)
            var scanned = WineDraft()
            scanned.fill(from: result)
            scanned.imageData = photoData
            draft = scanned
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // Nieuwe wijn opslaan.
    private func save(_ draft: WineDraft) {
        let wine = Wine()
        context.insert(wine)
        draft.apply(to: wine)
        dismiss()
    }
}

#Preview {
    AddWineView()
        .modelContainer(PreviewData.container)
}
