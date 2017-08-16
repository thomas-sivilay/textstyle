//
//  TextStyle.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

public struct TextStyle {
    var text: String
    var style: StyleOrAttributes
    
    public init(text: String = "", style: StyleOrAttributes) {
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
        
        // To refactor
        if let style = try? container.decodeIfPresent(Style.self, forKey: .style) {
            self = TextStyle(text: text, style: StyleOrAttributes.attributes(style: style!))
        } else if let name = try? container.decodeIfPresent(String.self, forKey: .style) {
            self = TextStyle(text: text, style: StyleOrAttributes.style(name: name!))
        } else {
            fatalError()
        }
    }
}
