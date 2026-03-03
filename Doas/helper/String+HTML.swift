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
