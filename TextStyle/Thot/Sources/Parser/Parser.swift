//
//  Parser.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

public class ElementParser {
    class func parse(text: String) -> [Element] {
        var tokenizer = Lexer(text: text)
        return try! self.parse(with: tokenizer)
    }
    
    private enum Step {
        case open
        case content
        case close
        case unknown
    }
    
    class func parse(with tokenizer: Lexer) throws -> [Element] {
        var tokenizer = tokenizer
        var elements = [Element]()
        var element = Element()
        var subElement = Element()
        
        while let token = try tokenizer.nextToken() {
            switch token {
            case let .openTag(tag):
                element.openTag = tag
            case let .closeTag(tag):
                element.closeTag = tag
                elements.append(element)
                element = Element()
            case let .string(s):
                if subElement.openTag != "" {
                    subElement.content = s
                } else {
                    element.content = s
                }
            case let .openMarkdown(d):
                let markdownSymbol = d == .emphasize ? "em" : "st"
                if element.openTag != "" {
                    subElement.openTag = "\(element.openTag):\(markdownSymbol)"
                } else {
                    element.openTag = markdownSymbol
                }
            case let .closeMarkdown(d):
                let markdownSymbol = d == .emphasize ? "em" : "st"
                if element.openTag != "" && subElement.openTag != "" {
                    subElement.closeTag = "\(element.openTag):\(markdownSymbol)"
                    elements.append(subElement)
                    subElement = Element()
                } else {
                    element.closeTag = markdownSymbol
                    elements.append(element)
                    element = Element()
                }
            }
        }
        
        return elements.filter { $0.content != "" }
    }
}
