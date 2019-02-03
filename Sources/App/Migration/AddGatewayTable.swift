//
//  AddGatewayTable.swift
//  App
//
//  Created by Nikolay Andonov on 3.02.19.
//

import Foundation
import FluentPostgreSQL
import Vapor

struct AddGatewayTable: PostgreSQLMigration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        
        return Database.create(Gateway.self, on: conn, closure: { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.codeIdentifier)
            builder.field(for: \.premiseId)
        })
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.delete(Gateway.self, on: conn)
    }
}


