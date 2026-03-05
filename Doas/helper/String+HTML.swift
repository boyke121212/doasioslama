//
//  String+HTML.swift
//  Doas
//
//  Created by Admin on 04/03/26.
//

import UIKit

extension String {

    func htmlToPlain() -> String {

        guard let data = self.data(using: .utf8) else {
            return self
        }

        do {
            let attributed = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )

            return attributed.string
        } catch {
            return self
        }
    }
}

extension String {
    func htmlPreviewClean(maxWords: Int = 20) -> String {
        guard let data = self.data(using: .utf8) else { return "" }
        
        let plainText: String
        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) {
            plainText = attributed.string
        } else {
            plainText = self
        }

        let cleaned = plainText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let words = cleaned.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        return words.count <= maxWords
            ? cleaned
            : words.prefix(maxWords).joined(separator: " ") + "..."
    }
}
