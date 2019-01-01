//
//  CommonModels.swift
//  App
//
//  Created by Nikolay Andonov on 27.12.18.
//

import Foundation
import Vapor

struct ResultWrapper<T: Content>: Content {
    let result: T?
}

struct FormattedResultWrapper: Content {
    enum Result: String, Content {
        case success = "success"
        case faliure = "faliure"
    }
    let result: Result?
}

struct ArrayResultWrapper<T: Content>: Content {
    let result: [T]?
}
