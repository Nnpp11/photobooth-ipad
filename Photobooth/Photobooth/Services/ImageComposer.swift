import UIKit
import ImageIO
import MobileCoreServices

class ImageComposer {

    // MARK: - Single Photo
    static func compose(single image: UIImage, template: PhotoTemplate?) -> UIImage {
        guard let tpl = template else { return image }
        return applyTemplate(to: image, template: tpl)
    }

    // MARK: - Strip (3 photos vertical)
    static func composeStrip(images: [UIImage], template: PhotoTemplate?) -> UIImage {
        let stripW: CGFloat = 800
        let photoH: CGFloat = 600
        let gap: CGFloat = 12
        let padding: CGFloat = 32
        let footerH: CGFloat = template != nil ? 80 : 0

        let totalH = padding + CGFloat(images.count) * photoH + CGFloat(images.count - 1) * gap + padding + footerH
        let size = CGSize(width: stripW, height: totalH)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let bg = UIColor(hex: template?.backgroundColor ?? "#0A0A0A")
            bg.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Gold border lines
            UIColor(hex: "#C9A84C").withAlphaComponent(0.4).setFill()
            ctx.fill(CGRect(x: 8, y: 8, width: stripW - 16, height: 2))
            ctx.fill(CGRect(x: 8, y: totalH - 10, width: stripW - 16, height: 2))

            // Photos
            for (i, image) in images.enumerated() {
                let y = padding + CGFloat(i) * (photoH + gap)
                let rect = CGRect(x: padding, y: y, width: stripW - padding * 2, height: photoH)
                drawImageFilled(image, in: rect, context: ctx.cgContext)
            }

            // Footer text
            if let tpl = template, !tpl.eventText.isEmpty {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "Georgia", size: 22) ?? UIFont.systemFont(ofSize: 22),
                    .foregroundColor: UIColor(hex: "#C9A84C")
                ]
                let str = NSAttributedString(string: tpl.eventText, attributes: attrs)
                let textRect = CGRect(x: padding, y: totalH - footerH + 10,
                                      width: stripW - padding * 2, height: 60)
                str.draw(in: textRect)
            }
        }
    }

    // MARK: - Grid (2x2)
    static func composeGrid(images: [UIImage], template: PhotoTemplate?) -> UIImage {
        let size = CGSize(width: 1200, height: 1200)
        let gap: CGFloat = 8
        let padding: CGFloat = 24
        let cellW = (size.width - padding * 2 - gap) / 2
        let cellH = (size.height - padding * 2 - gap) / 2

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(hex: template?.backgroundColor ?? "#0A0A0A").setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let positions: [CGPoint] = [
                CGPoint(x: padding, y: padding),
                CGPoint(x: padding + cellW + gap, y: padding),
                CGPoint(x: padding, y: padding + cellH + gap),
                CGPoint(x: padding + cellW + gap, y: padding + cellH + gap)
            ]

            for (i, image) in images.prefix(4).enumerated() {
                let rect = CGRect(origin: positions[i], size: CGSize(width: cellW, height: cellH))
                drawImageFilled(image, in: rect, context: ctx.cgContext)
            }
        }
    }

    // MARK: - GIF
    static func composeGIF(images: [UIImage]) -> Data? {
        let fileProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0
            ]
        ]
        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: 0.15
            ]
        ]

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, kUTTypeGIF, images.count, nil) else {
            return nil
        }
        CGImageDestinationSetProperties(dest, fileProperties as CFDictionary)

        for image in images {
            if let cgImage = image.cgImage {
                CGImageDestinationAddImage(dest, cgImage, frameProperties as CFDictionary)
            }
        }

        CGImageDestinationFinalize(dest)
        return data as Data
    }

    // MARK: - Template Overlay
    static func applyTemplate(to image: UIImage, template: PhotoTemplate) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: image.size))

            // Overlay PNG if present
            if let overlayData = template.overlayData,
               let overlay = UIImage(data: overlayData) {
                overlay.draw(in: CGRect(origin: .zero, size: image.size))
            }

            // Bottom text band
            if !template.eventText.isEmpty || !template.hashtag.isEmpty {
                let bandH: CGFloat = image.size.height * 0.08
                let bandRect = CGRect(x: 0, y: image.size.height - bandH,
                                      width: image.size.width, height: bandH)
                UIColor.black.withAlphaComponent(0.55).setFill()
                ctx.fill(bandRect)

                let text = [template.eventText, template.hashtag]
                    .filter { !$0.isEmpty }
                    .joined(separator: "  ·  ")
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: "Georgia", size: bandH * 0.4) ?? UIFont.systemFont(ofSize: 20),
                    .foregroundColor: UIColor(hex: "#C9A84C")
                ]
                let str = NSAttributedString(string: text, attributes: attrs)
                let textRect = CGRect(x: 24, y: image.size.height - bandH + bandH * 0.25,
                                      width: image.size.width - 48, height: bandH * 0.5)
                str.draw(in: textRect)
            }
        }
    }

    // MARK: - Helper
    private static func drawImageFilled(_ image: UIImage,
                                         in rect: CGRect,
                                         context: CGContext) {
        context.saveGState()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
        path.addClip()

        // Aspect fill
        let imgRatio = image.size.width / image.size.height
        let rectRatio = rect.width / rect.height
        var drawRect = rect
        if imgRatio > rectRatio {
            let w = rect.height * imgRatio
            drawRect = CGRect(x: rect.midX - w/2, y: rect.minY, width: w, height: rect.height)
        } else {
            let h = rect.width / imgRatio
            drawRect = CGRect(x: rect.minX, y: rect.midY - h/2, width: rect.width, height: h)
        }
        image.draw(in: drawRect)
        context.restoreGState()
    }
}

// MARK: - UIColor Hex
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1)
    }
}
