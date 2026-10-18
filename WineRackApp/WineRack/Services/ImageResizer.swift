import UIKit

// Verkleint foto's zodat ze snel verstuurd en zuinig bewaard worden.
enum ImageResizer {
    // Maximale langste zijde in pixels.
    static let apiMaxDimension: CGFloat = 1568
    static let storageMaxDimension: CGFloat = 1024
    static let thumbnailMaxDimension: CGFloat = 160

    // Tekent de foto opnieuw op maximaal `maxDimension` pixels (zet ook de draaiing goed).
    static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longest = max(pixelWidth, pixelHeight)
        guard longest > 0 else { return image }

        let factor = min(1, maxDimension / longest)
        let target = CGSize(width: max(1, (pixelWidth * factor).rounded()),
                            height: max(1, (pixelHeight * factor).rounded()))

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    // Verkleinde foto als JPEG-gegevens.
    static func jpegData(from image: UIImage, maxDimension: CGFloat, quality: CGFloat = 0.8) -> Data? {
        resized(image, maxDimension: maxDimension).jpegData(compressionQuality: quality)
    }

    // Kleine miniatuur voor de lijst, gemaakt van de bewaarde foto.
    static func thumbnailData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return jpegData(from: image, maxDimension: thumbnailMaxDimension, quality: 0.7)
    }

    // Maakt in één keer beide versies klaar, buiten de hoofdthread zodat de app niet hapert:
    // eerst 1568 px voor Claude, daarna 1024 px (gemaakt van die kleinere versie) om te bewaren.
    static func prepareForScan(_ image: UIImage) async -> (upload: Data?, stored: Data?) {
        await Task.detached(priority: .userInitiated) {
            let large = ImageResizer.resized(image, maxDimension: ImageResizer.apiMaxDimension)
            let upload = large.jpegData(compressionQuality: 0.8)
            let stored = ImageResizer.jpegData(from: large, maxDimension: ImageResizer.storageMaxDimension, quality: 0.7)
            return (upload, stored)
        }.value
    }
}
