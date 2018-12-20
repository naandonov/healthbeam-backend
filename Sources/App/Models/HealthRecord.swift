//
//  HealthRecord.swift
//  App
//
//  Created by Nikolay Andonov on 3.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class HealthRecord: Content {
    
    struct Request: Content {
        var id: Int?

        var diagnosis: String
        var treatment: String
        var prescription: String
        var createdDate: Date
        
        func model(with patientId: Patient.ID) -> HealthRecord {
            return HealthRecord(id: id,
                                diagnosis: diagnosis,
                                treatment: treatment,
                                prescription: prescription,
                                createdDate: createdDate,
                                patientId: patientId)
        }
    }
    
    var id: Int?
    
    var diagnosis: String
    var treatment: String
    var prescription: String
    var createdDate: Date
    var patientId: Patient.ID
    
    init(id: Int? = nil, diagnosis: String, treatment: String, prescription: String, createdDate: Date, patientId: Patient.ID) {
        self.id = id
        self.diagnosis = diagnosis
        self.treatment = treatment
        self.prescription = prescription
        self.createdDate = createdDate
        self.patientId = patientId
    }
    
}

extension HealthRecord: Migration {
//    public static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            builder.reference(from: \.patientId, to: \Patient.id)
//        }
//    }
}

extension HealthRecord: Parameter {}
extension HealthRecord: PostgreSQLModel {
    static var entity :String = "health_record"
}
