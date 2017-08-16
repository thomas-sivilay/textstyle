//
//  RichText.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

public struct RichText {
    var text: String
    
    public init(text: String = "") {
        self.text = text
    }
}

extension RichText: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let text = try container.decode(String.self)
        self = RichText(text: text)
    }
}
