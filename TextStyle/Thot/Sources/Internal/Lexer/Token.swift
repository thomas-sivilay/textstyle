//
//  Token.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

enum TagType {
    case open
    case close
}

enum Token {
    case string(String)
    case markdown(TagType, markdown: Markdown)
    case tag(TagType, name: String)
}
