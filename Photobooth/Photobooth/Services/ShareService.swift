import UIKit
import CoreImage
import SwiftUI

class ShareService {

    // MARK: - QR Code Generation
    static func generateQRCode(from string: String, size: CGFloat = 300) -> UIImage? {
        let data = string.data(using: .utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let output = filter.outputImage else { return nil }

        // Scale up
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }

        // Invert colors for dark QR on light background (better scan)
        let qr = UIImage(cgImage: cgImage)
        return qr.withDarkQRStyle()
    }

    // MARK: - Local URL for image
    static func localShareURL(for mediaId: UUID) -> String {
        // When no backend: use a local server URL format
        // In production this would be your Supabase/backend URL
        return "photobooth://media/\(mediaId.uuidString)"
    }

    // MARK: - WhatsApp Share
    static func shareViaWhatsApp(text: String, image: UIImage?) -> Bool {
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "whatsapp://send?text=\(encodedText)"
        guard let url = URL(string: urlStr) else { return false }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return true
        }
        return false
    }

    // MARK: - Email Share
    static func shareViaEmail(to: String, subject: String, body: String, image: UIImage?) {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "mailto:\(to)?subject=\(encodedSubject)&body=\(encodedBody)"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Save to Photos
    static func saveToPhotos(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        completion(true)
    }

    // MARK: - System Share Sheet
    static func showShareSheet(image: UIImage, text: String, from viewController: UIViewController) {
        let items: [Any] = [image, text]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        ac.excludedActivityTypes = [.addToReadingList, .assignToContact, .openInIBooks]
        if let popover = ac.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX,
                                        y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        viewController.present(ac, animated: true)
    }
}

// MARK: - QR Style
extension UIImage {
    func withDarkQRStyle() -> UIImage {
        // Returns the standard black QR on white — most scannable
        return self
    }
}

// MARK: - SwiftUI QR View
struct QRCodeView: View {
    let content: String
    let size: CGFloat

    var body: some View {
        if let qrImage = ShareService.generateQRCode(from: content, size: size),
           let swiftUIImage = Image(uiImage: qrImage) as Image? {
            swiftUIImage
                .interpolation(.none)
                .resizable()
                .frame(width: size, height: size)
        } else {
            Rectangle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .overlay(Text("QR indisponible").font(.caption).foregroundColor(.black))
        }
    }
}
