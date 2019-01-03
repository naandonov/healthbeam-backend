//
//  Hospital.swift
//  App
//
//  Created by Nikolay Andonov on 3.01.19.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Hospital: Content {
    
    struct Public: Content {
        var id: Int?
        var name: String
    }
    
    var id: Int?
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func mapToPublic() throws -> Public {
        return try Public(id: requireID(), name: name)
    }

}

extension Hospital: Migration {}
extension Hospital: Parameter {}
extension Hospital: PostgreSQLModel {}
