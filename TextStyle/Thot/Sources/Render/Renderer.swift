//
//  Renderer.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

public final class Renderer {
    
    // MARK: - Properties
    
    public var theme: Theme?
    public static let sharedInstance = Renderer()
    
    private let parser: ElementParser
    
    // MARK: - Initializer
    
    public init() {
        self.theme = nil
        self.parser = ElementParser()
    }
    
    // MARK: - Instance Methods
    
    public func render(_ label: UILabel, with renderable: Renderable) throws {
        switch renderable {
        case let textStyle as TextStyle:
            try render(label, with: textStyle)
        case let richText as RichText:
            try render(label, with: richText)
        default:
            break
        }
    }
    
    // MARK: - Private
    
    private func render(_ label: UILabel, with textStyle: TextStyle) throws {
        switch textStyle.style {
        case let .name(name):
            guard let theme = theme else {
                throw RendererError.theme(error: ThemeError.missingTheme)
            }
            guard let style = theme.style(with: name) else {
                throw RendererError.theme(error: ThemeError.missingStyle(name: name))
            }
            render(label, with: textStyle.text, and: style)
        case let .attributes(attributes):
            render(label, with: textStyle.text, and: attributes)
        }
    }
    
    private func render(_ label: UILabel, with richText: RichText) throws {
        guard let theme = theme else {
            throw RendererError.theme(error: ThemeError.missingTheme)
        }
        
        try render(label, with: richText.text, and: theme)
    }
    
    private func render(_ label: UILabel, with text: String, and theme: Theme) throws {
        do {
            label.attributedText = try makeAttributedString(for: text, with: theme)
            label.numberOfLines = 0
        } catch {
            throw error
        }
    }
    
    private func render(_ label: UILabel, with text: String, and attributes: StyleAttributes) {
        label.attributedText = makeAttributedString(for: text, with: attributes)
        label.numberOfLines = attributes.numberOfLines
    }
    
    private func makeAttributedString(for text: String, with theme: Theme) throws -> NSAttributedString {
        let lexer = CharacterLexer(text: text)
        let elements = try parser.parse(with: lexer)
        var richText = [(String, StyleAttributes)]()
        
        let aText = NSMutableAttributedString()
        
        try elements.forEach { element in
            guard let style = theme.style(with: element.openTag) else {
                throw RendererError.theme(error: ThemeError.missingStyle(name: element.openTag))
            }
            guard element.openTag == element.closeTag else {
                throw RendererError.element(error: ElementError.unconsistentOpenCloseTag(open: element.openTag, close: element.closeTag))
            }
            
            richText.append((element.content, style))
        }
        
        richText.forEach {
            aText.append(makeAttributedString(for: $0.0, with: $0.1))
        }
        
        return aText
    }
    
    private func makeAttributedString(for text: String, with styleAttributes: StyleAttributes) -> NSAttributedString {
        let attributes = makeAttributes(for: styleAttributes)
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    private func makeAttributes(for styleAttributes: StyleAttributes) -> [NSAttributedStringKey: Any] {
        var attributes = [NSAttributedStringKey: Any]()
        attributes[NSAttributedStringKey.foregroundColor] = styleAttributes.color
        attributes[NSAttributedStringKey.backgroundColor] = styleAttributes.backgroundColor
        
        if styleAttributes.markdown == Markdown.emphasize {
            attributes[NSAttributedStringKey.font] = UIFont.italicSystemFont(ofSize: styleAttributes.size)
        } else if styleAttributes.markdown == Markdown.strong {
            attributes[NSAttributedStringKey.font] = UIFont.boldSystemFont(ofSize: styleAttributes.size)
        } else {
            attributes[NSAttributedStringKey.font] = UIFont.systemFont(ofSize: styleAttributes.size)
        }
        
        attributes[NSAttributedStringKey.kern] = styleAttributes.kern
        attributes[NSAttributedStringKey.paragraphStyle] = makeParagraphStyle(for: styleAttributes)
        
        return attributes
    }
    
    private func makeParagraphStyle(for styleAttributes: StyleAttributes) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = styleAttributes.alignment
        paragraphStyle.lineHeightMultiple = styleAttributes.lineHeightMultiple
        paragraphStyle.paragraphSpacing = styleAttributes.paragraphSpacing
        
        return paragraphStyle
    }
}
