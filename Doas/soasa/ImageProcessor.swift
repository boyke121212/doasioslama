import UIKit

class ImageProcessor {

    static func processAndSave(
        file: URL,
        isFrontCamera: Bool,
        alamat: String,
        lat: Double?,
        lon: Double?,
        quality: Int = 50
    ) -> URL {

        guard let original = UIImage(contentsOfFile: file.path) else {
            return file
        }

        let rotated = fixOrientation(
            original,
            file: file,
            isFrontCamera: isFrontCamera
        )

        let resized = resizeBitmap(rotated, maxSize: 720)

        let watermarked = addWatermark(
            resized,
            alamat: alamat,
            lat: lat,
            lon: lon
        )

        let newFile = file
            .deletingPathExtension()
            .appendingPathExtension("jpg")

        let compression = CGFloat(quality) / 100.0

        if let data = watermarked.jpegData(compressionQuality: compression) {
            try? data.write(to: newFile)
        }

        if file.path != newFile.path {
            try? FileManager.default.removeItem(at: file)
        }

        return newFile
    }

    // ================= ROTASI =================
    private static func fixOrientation(
        _ image: UIImage,
        file: URL,
        isFrontCamera: Bool
    ) -> UIImage {

        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { ctx in

            if isFrontCamera {

                ctx.cgContext.translateBy(x: image.size.width, y: 0)
                ctx.cgContext.scaleBy(x: -1, y: 1)
            }

            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    // ================= RESIZE =================

    private static func resizeBitmap(
        _ bitmap: UIImage,
        maxSize: CGFloat
    ) -> UIImage {

        let width = bitmap.size.width
        let height = bitmap.size.height

        if width <= maxSize && height <= maxSize {
            return bitmap
        }

        let ratio = width / height

        let newWidth: CGFloat
        let newHeight: CGFloat

        if ratio > 1 {
            newWidth = maxSize
            newHeight = maxSize / ratio
        } else {
            newHeight = maxSize
            newWidth = maxSize * ratio
        }

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: newWidth, height: newHeight)
        )

        return renderer.image { _ in
            bitmap.draw(in: CGRect(
                x: 0,
                y: 0,
                width: newWidth,
                height: newHeight
            ))
        }
    }

    // ================= WATERMARK =================
    
        private static func addWatermark(
        _ bitmap: UIImage,
        alamat: String,
        lat: Double?,
        lon: Double?
    ) -> UIImage {

        print("WATERMARK RUN")

        let renderer = UIGraphicsImageRenderer(size: bitmap.size)

        return renderer.image { ctx in

            bitmap.draw(in: CGRect(origin: .zero, size: bitmap.size))

            let textSize = bitmap.size.width * 0.05

            let waktuFormatter = DateFormatter()
            waktuFormatter.dateFormat = "yyyy-MM-dd HH:mm"

            let waktu = waktuFormatter.string(from: Date())

            let latlonText: String

            if let lat = lat, let lon = lon {
                latlonText = String(format: "Lat %.5f  Lon %.5f", lat, lon)
            } else {
                latlonText = "Lat/Lon tidak tersedia"
            }

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left

            let shadow = NSShadow()
            shadow.shadowBlurRadius = 4
            shadow.shadowColor = UIColor.black

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: textSize),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph,
                .shadow: shadow
            ]

            let lines = [
                waktu,
                alamat,
                latlonText
            ]

            let padding = textSize * 0.6
            let lineHeight = textSize * 1.4

            let boxHeight = CGFloat(lines.count) * lineHeight + padding * 2

            let rect = CGRect(
                x: padding,
                y: bitmap.size.height - boxHeight - padding,
                width: bitmap.size.width - padding * 2,
                height: boxHeight
            )

            // background box
            UIColor.black.withAlphaComponent(0.4).setFill()
            UIBezierPath(rect: rect).fill()

            var y = bitmap.size.height - boxHeight + lineHeight

            for line in lines {

                let textRect = CGRect(
                    x: padding * 2,
                    y: y,
                    width: bitmap.size.width - padding * 3,
                    height: lineHeight
                )

                (line as NSString).draw(
                    in: textRect,
                    withAttributes: attributes
                )

                y += lineHeight
            }
        }
    }

    // ================= WRAP TEXT =================

    private static func wrapText(
        _ text: String,
        attributes: [NSAttributedString.Key: Any],
        maxWidth: CGFloat
    ) -> [String] {

        let words = text.split(separator: " ")

        var lines: [String] = []
        var currentLine = ""

        for word in words {

            let testLine =
                currentLine.isEmpty
                ? String(word)
                : currentLine + " " + word

            let size = (testLine as NSString)
                .size(withAttributes: attributes)

            if size.width <= maxWidth {

                currentLine = testLine

            } else {

                lines.append(currentLine)
                currentLine = String(word)
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines
    }
}
