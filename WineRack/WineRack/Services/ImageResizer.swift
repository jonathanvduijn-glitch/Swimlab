import UIKit

// Verkleint foto's zodat ze snel verstuurd en zuinig bewaard worden.
enum ImageResizer {
    // Maximale langste zijde in pixels.
    static let apiMaxDimension: CGFloat = 1568
    static let storageMaxDimension: CGFloat = 1024

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
}
