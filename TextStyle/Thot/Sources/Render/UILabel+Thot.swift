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
    
    func setText(_ text: String, with attributes: StyleAttributes) {
        self.attributedText = makeAttributedString(for: text, with: attributes)
        self.numberOfLines = attributes.numberOfLines
    }
    
    private func makeAttributedString(for text: String, with theme: Theme) -> NSAttributedString {
        let elements = ElementParser.parse(text: text)
        var richText = [(String, StyleAttributes)]()
        
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
    
    private func makeAttributedString(for text: String, with styleAttributes: StyleAttributes) -> NSAttributedString {
        let attributes = makeAttributes(for: styleAttributes)
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    private func makeAttributes(for styleAttributes: StyleAttributes) -> [NSAttributedStringKey: Any] {
        var attributes = [NSAttributedStringKey: Any]()
        attributes[NSAttributedStringKey.foregroundColor] = styleAttributes.color
        
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
