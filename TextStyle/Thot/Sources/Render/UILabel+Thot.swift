//
//  UILabel+Thot.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

extension UILabel {
    func setRichText(_ text: String, with theme: Theme) {
        self.attributedText = makeAttributedString(for: text, with: theme)
        self.numberOfLines = 0
    }
    
    func setText(_ text: String, with style: Style) {
        self.attributedText = makeAttributedString(for: text, with: style)
        self.numberOfLines = style.numberOfLines
    }
    
    private func makeAttributedString(for text: String, with theme: Theme) -> NSAttributedString {
        let elements = ElementParser.parse(text: text)
        var richText = [(String, Style)]()
        
        let aText = NSMutableAttributedString()
        
        elements.forEach { element in
            if let style = theme.style(with: element.openTag), element.openTag == element.closeTag {
                richText.append((element.content, style))
            } else {
                // error
                print("ERROR, can't find style with name: \(element.openTag)")
            }
        }
        
        richText.forEach {
            aText.append(makeAttributedString(for: $0.0, with: $0.1))
        }
        
        return aText
    }
    
    private func makeAttributedString(for text: String, with style: Style) -> NSAttributedString {
        let attributes = makeAttributes(for: style)
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    private func makeAttributes(for style: Style) -> [NSAttributedStringKey: Any] {
        var attributes = [NSAttributedStringKey: Any]()
        attributes[NSAttributedStringKey.foregroundColor] = style.color
        
        if style.markdown == Markdown.emphasize {
            attributes[NSAttributedStringKey.font] = UIFont.italicSystemFont(ofSize: style.size)
        } else if style.markdown == Markdown.strong {
            attributes[NSAttributedStringKey.font] = UIFont.boldSystemFont(ofSize: style.size)
        } else {
            attributes[NSAttributedStringKey.font] = UIFont.systemFont(ofSize: style.size)
        }
        
        attributes[NSAttributedStringKey.kern] = style.kern
        attributes[NSAttributedStringKey.paragraphStyle] = makeParagraphStyle(for: style)
        
        return attributes
    }
    
    private func makeParagraphStyle(for style: Style) -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = style.alignment
        paragraphStyle.lineHeightMultiple = style.lineHeightMultiple
        paragraphStyle.paragraphSpacing = style.paragraphSpacing
        
        return paragraphStyle
    }
}
