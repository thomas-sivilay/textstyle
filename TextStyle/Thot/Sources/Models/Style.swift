//
//  Style.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

public struct Style: Decodable {
    let name: String?
    let size: CGFloat
    let color: UIColor
    let alignment: NSTextAlignment
    let kern: CGFloat
    let lineHeightMultiple: CGFloat
    let paragraphSpacing: CGFloat
    let numberOfLines: Int
    var markdown: Markdown
    
    private enum CodingKeys: String, CodingKey {
        case name
        case size
        case color
        case alignment
        case kern
        case lineHeightMultiple
        case paragraphSpacing
        case numberOfLines
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let name = try values.decodeIfPresent(String.self, forKey: .name)
        let size = try values.decodeIfPresent(CGFloat.self, forKey: .size)
        let colorString = try values.decodeIfPresent(String.self, forKey: .color)
        let alignmentString = try values.decodeIfPresent(String.self, forKey: .alignment)
        let kern = try values.decodeIfPresent(CGFloat.self, forKey: .kern)
        let lineHeightMultiple = try values.decodeIfPresent(CGFloat.self, forKey: .lineHeightMultiple)
        let paragraphSpacing = try values.decodeIfPresent(CGFloat.self, forKey: .paragraphSpacing)
        let numberOfLines = try values.decodeIfPresent(Int.self, forKey: .numberOfLines)
        
        let color = ColorAdapter.uiColor(from: colorString) ?? .black
        let alignment = AlignmentAdapter.nsTextAlignment(from: alignmentString) ?? .natural
        
        self = .init(name: name,
                     size: size ?? 13.0,
                     color: color,
                     alignment: alignment,
                     kern: kern ?? 0.0,
                     lineHeightMultiple: lineHeightMultiple ?? 0.0,
                     paragraphSpacing: paragraphSpacing ?? 0.0,
                     numberOfLines: numberOfLines ?? 1,
                     markdown: .none)
        return
    }
    
    init(name: String? = nil,
         size: CGFloat = 13.0,
         color: UIColor = .black,
         alignment: NSTextAlignment = .natural,
         kern: CGFloat = 0.0,
         lineHeightMultiple: CGFloat = 0.0,
         paragraphSpacing: CGFloat = 0.0,
         numberOfLines: Int = 1,
         markdown: Markdown = .none
        ) {
        self.name = name
        self.size = size
        self.color = color
        self.alignment = alignment
        self.kern = kern
        self.lineHeightMultiple = lineHeightMultiple
        self.paragraphSpacing = paragraphSpacing
        self.numberOfLines = numberOfLines
        self.markdown = markdown
    }
}

final class ColorAdapter {
    class func uiColor(from string: String?) -> UIColor? {
        guard let string = string else {
            return nil
        }
        
        switch string {
        case "black":
            return .black
        case "white":
            return .white
        case "red":
            return .red
        case "blue":
            return .blue
        case "green":
            return .green
        default:
            return nil
        }
    }
}

final class AlignmentAdapter {
    class func nsTextAlignment(from string: String?) -> NSTextAlignment? {
        guard let string = string else {
            return nil
        }
        
        switch string {
        case "natural":
            return .natural
        case "left":
            return .left
        case "right":
            return .right
        case "center":
            return .center
        default:
            return nil
        }
    }
}
