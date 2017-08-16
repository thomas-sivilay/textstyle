//
//  StyleOrAttributes.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/16/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

public enum StyleOrAttributes {
    case style(name: String)
    case attributes(style: Style)
}
