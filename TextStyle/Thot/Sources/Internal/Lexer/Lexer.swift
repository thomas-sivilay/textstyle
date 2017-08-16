//
//  Lexer.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

struct Lexer {
    private var iterator: String.CharacterView.Iterator
    private var pushedBackCharacter: Character?
    private var buffer = String()
    private var previousMarkdown: Markdown?
    
    // MARK: - Initializer
    
    init(text: String) {
        iterator = text.characters.makeIterator()
    }
    
    // MARK: -
    
    mutating func nextToken() throws -> Token? {
        while var ch = nextCharacter() {
            switch ch {
            case "\\":
                if let nch = nextCharacter() {
                    buffer.append(nch)
                    ch = nch
                }
                break
            case "*", "_":
                if let res = checkBuffer(with: ch) {
                    return .string(res)
                } else {
                    return try markdown(startingWith: ch)
                }
            case "<":
                if let res = checkBuffer(with: ch) {
                    return .string(res)
                } else {
                    return try tag()
                }
            default:
                buffer.append(ch)
            }
        }
        return nil
    }
    
    // MARK: - Private
    
    private mutating func checkBuffer(with character: Character) -> String? {
        if buffer.characters.count > 0 {
            let res = buffer
            buffer = String()
            pushedBackCharacter = character
            return res
        } else {
            return nil
        }
    }
    
    private mutating func markdown(startingWith character: Character) throws -> Token {
        while let ch = nextCharacter() {
            switch ch {
            case character:
                if let markdown = previousMarkdown {
                    if markdown == .emphasize {
                        pushedBackCharacter = ch
                    }
                    previousMarkdown = nil
                    return .markdown(.close, markdown: markdown)
                }
                previousMarkdown = .strong
                return .markdown(.open, markdown: .strong)
            default:
                pushedBackCharacter = ch
                if let markdown = previousMarkdown {
                    previousMarkdown = nil
                    return .markdown(.close, markdown: markdown)
                }
                previousMarkdown = .emphasize
                return .markdown(.open, markdown: .emphasize)
            }
        }
        if let markdown = previousMarkdown {
            previousMarkdown = nil
            return .markdown(.close, markdown: markdown)
        }
        previousMarkdown = .emphasize
        return .markdown(.open, markdown: .emphasize)
    }
    
    private mutating func tag() throws -> Token {
        var tokenText = String()
        while let ch = nextCharacter() {
            switch ch {
            case ">":
                if tokenText.first == "/" {
                    tokenText.removeFirst()
                    return .tag(.close, name: tokenText)
                } else {
                    return .tag(.open, name: tokenText)
                }
            default:
                tokenText.append(ch)
            }
        }
        
        throw LexerError.invalidTag
    }
    
    private mutating func nextCharacter() -> Character? {
        if let next = pushedBackCharacter {
            pushedBackCharacter = nil
            return next
        }
        return iterator.next()
    }
}
