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
    
    struct Public {
        let id: Int
        var codeIdentifier: String
        let premise: Premise.Public
    }
    var id: Int?
    var codeIdentifier: String
    var premiseId: Premise.ID
    
    func mapToPublic(forPremise premise: Premise.Public) throws -> Gateway.Public {
        return try Public(id: requireID(), codeIdentifier: codeIdentifier, premise: premise)
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
