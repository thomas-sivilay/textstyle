//
//  Lexer.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/18/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

protocol Lexer {
    init(text: String)
    mutating func nextToken() throws -> Token?
}

