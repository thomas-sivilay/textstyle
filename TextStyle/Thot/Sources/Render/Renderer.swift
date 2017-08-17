//
//  Render.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

public final class Renderer {
    public var theme: Theme?
    
    public func render(label: UILabel, with textStyle: TextStyle) throws {
        switch textStyle.style {
        case let .name(name):
            if let theme = theme, let themeStyle = theme.styles[name] {
                try label.setText(textStyle.text, with: themeStyle)
            }
        case let .attributes(attributes):
            try label.setText(textStyle.text, with: attributes)
        }
    }
    
    public init() {
        self.theme = nil
    }
    
    public func render(label: UILabel, with richText: RichText) throws {
        try label.setRichText(richText.text, with: theme!)
        label.numberOfLines = 0
    }
}
