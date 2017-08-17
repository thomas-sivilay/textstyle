//
//  Theme.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

public struct Theme: Decodable {
    let styles: [String: StyleAttributes] // name-id: Style
    
    func style(with tag: String) -> StyleAttributes? {
        let splittedTag = tag.split(separator: ":")
        let styleName = splittedTag[0]
        var style = styles[String(styleName)]
        
        if splittedTag.count > 1 {
            let markdown = splittedTag[1]
            switch markdown {
            case "em":
                style?.markdown = .emphasize
                break
            case "st":
                style?.markdown = .strong
                break
            default:
                break
            }
        }
        
        return style
    }
}
