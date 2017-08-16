//
//  Element.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

struct Element {
    var openTag: String
    var content: String
    var closeTag: String
    
    init(openTag: String = "",
         content: String = "",
         closeTag: String = "") {
        self.openTag = openTag
        self.content = content
        self.closeTag = closeTag
    }
}
