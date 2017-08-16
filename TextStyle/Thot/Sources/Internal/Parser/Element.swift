//
//  Element.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

struct Element {
    private(set) var openTag: String
    private(set) var content: String
    private(set) var closeTag: String
    
    init(openTag: String = "",
         content: String = "",
         closeTag: String = "") {
        self.openTag = openTag
        self.content = content
        self.closeTag = closeTag
    }
    
    mutating func set(with token: Token) {
        switch token {
        case let .tag(.open, name: name):
            self.openTag = name
        case let .tag(.close, name: name):
            self.closeTag = name
        case let .string(s):
            self.content = s
        default:
            break
        }
    }
    
    mutating func set(with text: String, tagType: TagType) {
        switch tagType {
        case .close:
            self.closeTag = text
        case .open:
            self.openTag = text
        }
    }
}
