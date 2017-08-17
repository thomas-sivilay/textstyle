//
//  ColorAdapter.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/17/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

enum ColorAdapterError: Error {
    case emptyColor
    case unknownColor(String)
    case invalidHex(String)
}

final class ColorAdapter {
    
    class func uiColor(from string: String?) throws -> UIColor? {
        guard let string = string else {
            return nil
        }
        
        switch string {
        case "black":
            return .black
        case "darkGray", "darkGrey":
            return .darkGray
        case "lightGray", "lightGrey":
            return .lightGray
        case "white":
            return .white
        case "gray", "grey":
            return .gray
        case "red":
            return .red
        case "green":
            return .green
        case "blue":
            return .blue
        case "cyan":
            return .cyan
        case "yellow":
            return .yellow
        case "magenta":
            return .magenta
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "brown":
            return .brown
        case "clear":
            return .clear
        default:
            return try uiColor(with: string)
        }
    }
    
    private class func uiColor(with hexString: String) throws -> UIColor {
        let cleanString = clean(string: hexString)
        
        guard cleanString.characters.count == 6 else {
            if hexString.hasPrefix("#") {
                throw ColorAdapterError.invalidHex(hexString)
            } else {
                throw ColorAdapterError.unknownColor(hexString)
            }
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string: cleanString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    private class func clean(string: String) -> String {
        var res = string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if res.hasPrefix("#") {
            res.removeFirst()
        }
        
        return res
    }
}

