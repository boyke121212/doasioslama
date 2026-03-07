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

        guard let original = UIImage(contentsOfFile: file.path) else { return file }

        let rotated     = fixOrientation(original, file: file, isFrontCamera: isFrontCamera)
        let resized     = resizeBitmap(rotated, maxSize: 720)
        let watermarked = addWatermark(resized, alamat: alamat, lat: lat, lon: lon)

        let newFile = file.deletingPathExtension().appendingPathExtension("jpg")
        let compression = CGFloat(quality) / 100.0

        if let data = watermarked.jpegData(compressionQuality: compression) {
            try? data.write(to: newFile)
        }
        if file.path != newFile.path { try? FileManager.default.removeItem(at: file) }

        return newFile
    }

    // ================= ROTASI =================
    private static func fixOrientation(_ image: UIImage, file: URL, isFrontCamera: Bool) -> UIImage {
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
    private static func resizeBitmap(_ bitmap: UIImage, maxSize: CGFloat) -> UIImage {
        let w = bitmap.size.width, h = bitmap.size.height
        guard w > maxSize || h > maxSize else { return bitmap }
        let ratio = w / h
        let (nw, nh): (CGFloat, CGFloat) = ratio > 1
            ? (maxSize, maxSize / ratio)
            : (maxSize * ratio, maxSize)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: nw, height: nh))
        return renderer.image { _ in
            bitmap.draw(in: CGRect(x: 0, y: 0, width: nw, height: nh))
        }
    }

    // ================= WATERMARK =================
    private static func addWatermark(
        _ bitmap: UIImage,
        alamat: String,
        lat: Double?,
        lon: Double?
    ) -> UIImage {

        let renderer = UIGraphicsImageRenderer(size: bitmap.size)

        return renderer.image { ctx in
            bitmap.draw(in: CGRect(origin: .zero, size: bitmap.size))

            let textSize   = bitmap.size.width * 0.03   // lebih kecil
            let padding    = textSize * 0.6
            let lineHeight = textSize * 1.3
            let maxWidth   = bitmap.size.width - padding * 3

            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd HH:mm"
            let waktu = fmt.string(from: Date())

            let latlonText = lat != nil && lon != nil
                ? String(format: "Lat %.5f  Lon %.5f", lat!, lon!)
                : "Lat/Lon tidak tersedia"

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

            // ✅ Wrap alamat yang panjang — pakai wrapText
            let rawLines = [waktu, alamat, latlonText]
            var allLines: [String] = []
            for line in rawLines {
                let wrapped = wrapText(line, attributes: attributes, maxWidth: maxWidth)
                allLines.append(contentsOf: wrapped)
            }

            // Box height dihitung dari jumlah baris setelah wrap
            let boxHeight = CGFloat(allLines.count) * lineHeight + padding * 2

            let boxRect = CGRect(
                x: padding,
                y: bitmap.size.height - boxHeight - padding,
                width: bitmap.size.width - padding * 2,
                height: boxHeight
            )

            UIColor.black.withAlphaComponent(0.25).setFill()  // lebih transparan
            UIBezierPath(rect: boxRect).fill()

            // Mulai dari dalam box (atas box + padding)
            var y = boxRect.minY + padding

            for line in allLines {
                let textRect = CGRect(
                    x: boxRect.minX + padding,
                    y: y,
                    width: maxWidth,
                    height: lineHeight
                )
                (line as NSString).draw(in: textRect, withAttributes: attributes)
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
            let testLine = currentLine.isEmpty ? String(word) : currentLine + " " + word
            let size = (testLine as NSString).size(withAttributes: attributes)
            if size.width <= maxWidth {
                currentLine = testLine
            } else {
                if !currentLine.isEmpty { lines.append(currentLine) }
                currentLine = String(word)
            }
        }
        if !currentLine.isEmpty { lines.append(currentLine) }
        return lines.isEmpty ? [text] : lines
    }
}
