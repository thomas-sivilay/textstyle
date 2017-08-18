//
//  TextStyle.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

public struct TextStyle: Renderable {
    var text: String
    var style: Style
    
    public init(text: String = "", style: Style) {
        self.text = text
        self.style = style
    }
}

extension TextStyle: Decodable {
    private enum CodingKeys: String, CodingKey {
        case text
        case style
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let text = try container.decode(String.self, forKey: .text)
        
        // This optional try is messing up with StyleAttributes possible errors
        let styleAttributes = try? container.decodeIfPresent(StyleAttributes.self, forKey: .style)
        let name = try? container.decodeIfPresent(String.self, forKey: .style)
        
        switch (styleAttributes, name) {
        case (.some(.some(let a)), .none):
            self = TextStyle(text: text, style: Style.attributes(a))
        case (.none, .some(.some(let b))):
            self = TextStyle(text: text, style: Style.name(b))
        default:
            throw TextStyleError.missingNameOrStyleAttributes
        }
    }
}

enum TextStyleError: Error {
    case missingNameOrStyleAttributes
}
