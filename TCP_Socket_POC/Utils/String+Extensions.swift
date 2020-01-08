//
//  String+Extensions.swift
//  popguide
//
//  Created by Sumit Anantwar on 22/12/2018.
//  Copyright © 2019 Populi Ltd. All rights reserved.
//

import Foundation

extension String {

    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }

    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }

    var lenght: Int { return self.count }

    /// Simple localization
    var localized: String { return NSLocalizedString(self, comment: self) }

    /// Appending path component (like `NSString`)
    func appendingPathComponent(path: String) -> String {
        return (self as NSString).appendingPathComponent(path)
    }

    /// convert String to Int
    func toInt() -> Int? {
        return Int(self)
    }
    
    var isNotEmpty: Bool { return self.count > 0 }
}

extension Optional where Wrapped == String {
    var isNotNilOrEmpty: Bool {
        return self?.isNotEmpty ?? false
    }
}
