//
//  RendererError.swift
//  Thot
//
//  Created by Thomas Sivilay on 8/17/17.
//  Copyright © 2017 Thomas Sivilay. All rights reserved.
//

import Foundation

enum RendererError: Error {
    case element(error: ElementError)
    case theme(error: ThemeError)
}
