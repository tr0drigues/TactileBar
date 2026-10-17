import CoreGraphics
import CoreImage
import Foundation

public enum QRCodeGeneratorService {
    public static func generateCGImage(
        from url: URL,
        dimension: Double = AppConfiguration.LayoutMetrics.qrCodeDimensionPixels
    ) -> CGImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        let payloadData = Data(url.absoluteString.utf8)
        filter.setValue(payloadData, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let extent = outputImage.extent.integral
        guard extent.width > 0, extent.height > 0 else {
            return nil
        }

        let scaleX = dimension / extent.width
        let scaleY = dimension / extent.height
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext(options: [.useSoftwareRenderer: false])
        return context.createCGImage(transformed, from: transformed.extent)
    }
}
