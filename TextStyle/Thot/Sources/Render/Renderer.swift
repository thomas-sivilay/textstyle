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
    
    public func render(label: UILabel, with textStyle: TextStyle) {
        var style = Style()
        
        switch textStyle.style {
        case let .style(name):
            if let theme = theme, let themeStyle = theme.styles[name] {
                style = themeStyle
            }
        case let .attributes(attributes):
            style = attributes
        }
        
        label.setText(textStyle.text, with: style)
    }
    
    public init() {
        self.theme = nil
    }
    
    public func render(label: UILabel, with richText: RichText) {
        label.setRichText(richText.text, with: theme!)
        label.numberOfLines = 0
    }
}
