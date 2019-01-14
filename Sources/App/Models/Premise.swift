//
//  Premise.swift
//  App
//
//  Created by Nikolay Andonov on 3.01.19.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Premise: Content {
    
    struct Public: Content {
        var id: Int?
        var name: String
        var type: String
    }
    
    var id: Int?
    var name: String
    var type: String
    
    init(name: String, type: String) {
        self.name = name
        self.type = type
    }
    
    func mapToPublic() throws -> Public {
        return try Public(id: requireID(), name: name, type:type)
    }

}

extension Premise: Migration {}
extension Premise: Parameter {}
extension Premise: PostgreSQLModel {}
