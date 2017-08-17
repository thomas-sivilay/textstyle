//
//  AlignmentAdapter.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/17/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

enum AlignmentAdapterError: Error {
    case emptyAlignment
    case unknownAlignment(String)
}

final class AlignmentAdapter {
    class func nsTextAlignment(from string: String?) throws -> NSTextAlignment? {
        guard let string = string else {
            return nil
        }

        switch string {
        case "natural":
            return .natural
        case "justified":
            return .justified
        case "left":
            return .left
        case "right":
            return .right
        case "center":
            return .center
        default:
            throw AlignmentAdapterError.unknownAlignment(string)
        }
    }
}
