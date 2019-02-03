//
//  AddAditionalInfoAndChronicConditionsToPatient.swift
//  App
//
//  Created by Nikolay Andonov on 3.02.19.
//

import FluentPostgreSQL
import Vapor

struct AddAditionalInfoAndChronicConditionsToPatient: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Patient.self, on: conn, closure: { builder in
            builder.field(for: \.aditionalInfo)
            builder.field(for: \.chronicConditions)
//            let defaultValueConstraint =  PostgreSQLColumnConstraint.default(.literal(0))
//            builder.field(for: \.chronicConditions, type: .text, defaultValueConstraint)
        })
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.update(Patient.self, on: conn, closure: { builder in
            builder.deleteField(for: \.aditionalInfo)
            builder.deleteField(for: \.chronicConditions)
        })
    }
    
    typealias Database = PostgreSQLDatabase
}
