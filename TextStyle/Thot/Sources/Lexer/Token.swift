//
//  Token.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

enum Token {
    case string(String)
    case openMarkdown(Markdown)
    case closeMarkdown(Markdown)
    case openTag(String)
    case closeTag(String)
}
