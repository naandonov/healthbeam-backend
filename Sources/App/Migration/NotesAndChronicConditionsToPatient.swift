//
//  NotesAndChronicConditionsToPatient.swift
//  App
//
//  Created by Nikolay Andonov on 3.02.19.
//

import FluentPostgreSQL
import Vapor

struct NotesAndChronicConditionsToPatient: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Patient.self, on: conn, closure: { builder in
            builder.field(for: \.notes)
            
            let defaultValueConstraint =  PostgreSQLColumnConstraint.default(.literal("{}"))
            builder.field(for: \.chronicConditions, type: .array(.text), defaultValueConstraint)
        })
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Patient.self, on: conn, closure: { builder in
            builder.deleteField(for: \.notes)
            builder.deleteField(for: \.chronicConditions)
        })
    }
    
    typealias Database = PostgreSQLDatabase
}
