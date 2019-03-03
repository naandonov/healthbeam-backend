//
//  Gateway.swift
//  App
//
//  Created by Nikolay Andonov on 3.02.19.
//

import Foundation
import Vapor
import FluentPostgreSQL

struct Gateway: Content {
    
    struct Public: Content {
        let id: Int
        var codeIdentifier: String
        var name: String
        let premise: Premise.Public
    }
    
    struct Registration: Content {
        var codeIdentifier: String
        var name: String
    }
    
    var id: Int?
    var codeIdentifier: String
    var name: String
    var premiseId: Premise.ID
    
    func mapToPublic(forPremise premise: Premise.Public) throws -> Gateway.Public {
        return try Public(id: requireID(), codeIdentifier: codeIdentifier, name: name, premise: premise)
    }

}

extension Gateway {
    var hospital: Parent<Gateway, Premise> {
        return parent(\.premiseId)
    }
}

extension Gateway: Parameter {}
extension Gateway: PostgreSQLModel {}
extension Gateway: Migration {}
