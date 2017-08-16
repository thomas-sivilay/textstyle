//
//  Markdown.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

enum Markdown: Int {
    case none
    case emphasize // * * or _ _ -> italic
    case strong // ** ** or __ __ -> bold
    //    case strikethrough
    //    case underline
    //    case code // monospace
}
