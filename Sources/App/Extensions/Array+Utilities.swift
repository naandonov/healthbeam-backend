//
//  Array+Utilities.swift
//  App
//
//  Created by Nikolay Andonov on 27.12.18.
//

import Foundation
import Vapor

extension Array where Element: Content {
    func parse() -> ArrayResultWrapper<Element> {
        return ArrayResultWrapper(result: self)
    }
}
