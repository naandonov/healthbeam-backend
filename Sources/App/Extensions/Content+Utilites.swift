//
//  Content+Utilites.swift
//  App
//
//  Created by Nikolay Andonov on 27.12.18.
//

import Foundation
import Vapor

extension Content {
    func parse() -> ResultWrapper<Self> {
        return ResultWrapper(result: self)
    }
}
