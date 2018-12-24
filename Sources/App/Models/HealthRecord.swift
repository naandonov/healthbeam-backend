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
        var notes: String?
        var createdDate: Date
        
        func model(with patientId: Patient.ID) -> HealthRecord {
            return HealthRecord(id: id,
                                diagnosis: diagnosis,
                                treatment: treatment,
                                prescription: prescription,
                                notes: notes,
                                createdDate: createdDate,
                                patientId: patientId)
        }
    }
    
    struct Public: Content {
        var id: Int?
        
        var diagnosis: String
        var treatment: String
        var prescription: String
        var notes: String?
        var createdDate: Date
        var creator: User.ExternalPublic?
    }
    
    var id: Int?
    
    var diagnosis: String
    var treatment: String
    var prescription: String
    var notes: String?
    var createdDate: Date
    var patientId: Patient.ID
    var userId: User.ID?
    
    init(id: Int? = nil, diagnosis: String, treatment: String, prescription: String, notes: String? = nil, createdDate: Date, patientId: Patient.ID) {
        self.id = id
        self.diagnosis = diagnosis
        self.treatment = treatment
        self.prescription = prescription
        self.notes = notes
        self.createdDate = createdDate
        self.patientId = patientId
    }
    
    func mapToPublic(creator: User? = nil) throws -> HealthRecord.Public {
        return try HealthRecord.Public(id: requireID(),
                                       diagnosis: diagnosis,
                                       treatment: treatment,
                                       prescription: prescription,
                                       notes: notes,
                                       createdDate: createdDate,
                                       creator: creator?.mapToExternalPublic())
    }
    
}

extension HealthRecord {
    var creator: Parent<HealthRecord, User>? {
        return parent(\.userId)
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
extension HealthRecord: PostgreSQLModel {}
