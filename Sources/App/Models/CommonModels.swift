//
//  CommonModels.swift
//  App
//
//  Created by Nikolay Andonov on 27.12.18.
//

import Foundation
import Vapor

struct ResultParser<T: Content>: Content {
    let result: T?
}

struct ArrayResultParser<T: Content>: Content {
    let result: [T]?
}
