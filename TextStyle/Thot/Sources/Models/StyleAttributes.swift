//
//  StyleAttributes.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

public struct StyleAttributes {
    let name: String?
    let size: CGFloat
    let color: UIColor
    let backgroundColor: UIColor
    let alignment: NSTextAlignment
    let kern: CGFloat
    let maxLineHeight: CGFloat
    let minLineHeight: CGFloat
    let lineHeightMultiple: CGFloat
    let lineSpacing: CGFloat
    let paragraphSpacing: CGFloat
    let numberOfLines: Int
    var markdown: Markdown
}

extension StyleAttributes: Decodable {
    private enum CodingKeys: String, CodingKey {
        case name
        case size
        case color
        case backgroundColor
        case alignment
        case kern
        case maxLineHeight
        case minLineHeight
        case lineHeightMultiple
        case lineSpacing
        case paragraphSpacing
        case numberOfLines
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let name = try values.decodeIfPresent(String.self, forKey: .name)
        let size = try values.decodeIfPresent(CGFloat.self, forKey: .size)
        let colorString = try values.decodeIfPresent(String.self, forKey: .color)
        let backgroundColorString = try values.decodeIfPresent(String.self, forKey: .backgroundColor)
        let alignmentString = try values.decodeIfPresent(String.self, forKey: .alignment)
        let kern = try values.decodeIfPresent(CGFloat.self, forKey: .kern)
        let maxLineHeight = try values.decodeIfPresent(CGFloat.self, forKey: .maxLineHeight)
        let minLineHeight = try values.decodeIfPresent(CGFloat.self, forKey: .minLineHeight)
        let lineHeightMultiple = try values.decodeIfPresent(CGFloat.self, forKey: .lineHeightMultiple)
        let lineSpacing = try values.decodeIfPresent(CGFloat.self, forKey: .lineSpacing)
        let paragraphSpacing = try values.decodeIfPresent(CGFloat.self, forKey: .paragraphSpacing)
        let numberOfLines = try values.decodeIfPresent(Int.self, forKey: .numberOfLines)
        
        let color = try ColorAdapter.uiColor(from: colorString) ?? .black
        let backgroundColor = try ColorAdapter.uiColor(from: backgroundColorString) ?? .clear
        let alignment = try AlignmentAdapter.nsTextAlignment(from: alignmentString) ?? .natural
        
        self.name = name
        self.size = size ?? 13.0
        self.color = color
        self.backgroundColor = backgroundColor
        self.alignment = alignment
        self.kern = kern ?? 0.0
        self.maxLineHeight = maxLineHeight ?? 0.0
        self.minLineHeight = minLineHeight ?? 0.0
        self.lineHeightMultiple = lineHeightMultiple ?? 0.0
        self.lineSpacing = lineSpacing ?? 0.0
        self.paragraphSpacing = paragraphSpacing ?? 0.0
        self.numberOfLines = numberOfLines ?? 1
        self.markdown = .none
        
        return
    }
}
