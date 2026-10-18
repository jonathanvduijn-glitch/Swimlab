import SwiftUI

// Eén rij in de hoofdlijst.
struct WineRowView: View {
    let wine: Wine

    var body: some View {
        HStack(spacing: 12) {
            WineThumbnail(imageData: wine.labelImage, type: wine.type)

            VStack(alignment: .leading, spacing: 2) {
                Text(wine.displayName)
                    .font(.headline)
                    .lineLimit(1)
                if !wine.producer.isEmpty {
                    Text(wine.producer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 10) {
                    Label(wine.location.rawValue, systemImage: wine.location.icon)
                    if let drinkBy = wine.drinkBy {
                        Text(verbatim: "vóór \(drinkBy)")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Aantal flessen.
            Text(verbatim: "\(wine.quantity)×")
                .font(.title3.monospacedDigit())
                .foregroundStyle(wine.quantity == 0 ? Color.secondary : Color.primary)
        }
    }
}

// Miniatuur van het etiket, of een gekleurd glas als er geen foto is.
struct WineThumbnail: View {
    let imageData: Data?
    let type: WineType
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "wineglass.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(type.color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(type.color.opacity(0.15))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    List {
        WineRowView(wine: PreviewData.sampleWine)
    }
    .modelContainer(PreviewData.container)
}
