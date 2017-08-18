//
//  ElementParser.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

final class ElementParser {
    private enum Step {
        case open
        case content
        case close
        case unknown
    }
    
    func parse(with lexer: Lexer) throws -> [Element] {
        var lexer = lexer
        var elements = [Element]()
        var element = Element()
        var subElement = Element()
        
        while let token = try lexer.nextToken() {
            switch token {
            case let .tag(type, name: _):
                element.set(with: token)
                if type == .close {
                    elements.append(element)
                    element = Element()
                }
            case .string(_):
                if subElement.openTag != "" {
                    subElement.set(with: token)
                } else {
                    element.set(with: token)
                }
            case let .markdown(tagType, markdown: markdown):
                let markdownSymbol = markdown == .emphasize ? "em" : "st"
                if tagType == .open {
                    if element.openTag != "" {
                        subElement.set(with: "\(element.openTag):\(markdownSymbol)", tagType: tagType)
                    } else {
                        element.set(with: "\(markdownSymbol)", tagType: tagType)
                    }
                } else {
                    if element.openTag != "" && subElement.openTag != "" {
                        subElement.set(with: "\(element.openTag):\(markdownSymbol)", tagType: tagType)
                        elements.append(subElement)
                        subElement = Element()
                    } else {
                        element.set(with: "\(markdownSymbol)", tagType: tagType)
                        elements.append(element)
                        element = Element()
                    }
                }
            }
        }
        
        return elements.filter { $0.content != "" }
    }
}
