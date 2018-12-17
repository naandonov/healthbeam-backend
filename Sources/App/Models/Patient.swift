//
//  Patient.swift
//  App
//
//  Created by Nikolay Andonov on 3.12.18.
//

import Foundation
import Vapor
import FluentSQLite

final class Patient: Content {
    
    struct Subscribtion: Content {
        var patientId: Int
    }
    
    struct Public: Content {
        var id: Int
        var fullName: String
        var gender: String
        var personalIdentification: String
        var birthDate: Date
        var bloodType: String
        var alergies: [String]
        var premiseLocation: String
        var patientTag: PatientTag.Public?
        var healthRecords: [HealthRecord]?
    }
    
    var id: Int?
    
    var fullName: String
    var gender: String
    var personalIdentification: String
    var birthDate: Date
    var bloodType: String
    var alergies: [String]
    var premiseLocation: String
    
    var patientTagId: PatientTag.ID?
    
    
    init(fullName: String, gender: String, personalIdentification: String, birthDate: Date, bloodType: String, alergies: [String], premiseLocation: String) {
        self.fullName = fullName
        self.gender = gender
        self.personalIdentification = personalIdentification
        self.birthDate = birthDate
        self.bloodType = bloodType
        self.alergies = alergies
        self.premiseLocation = premiseLocation
    }
    
    func mapToPublic() throws -> Patient.Public {
        return try Patient.Public(id: requireID(), fullName: fullName, gender: gender, personalIdentification: personalIdentification, birthDate: birthDate, bloodType: bloodType, alergies: alergies, premiseLocation: premiseLocation, patientTag: nil, healthRecords: nil)
    }
}

extension Patient {
    var healthRecords: Children<Patient, HealthRecord> {
        return children(\.patientId)
    }
    
    var patientTag: Children<Patient, PatientTag> {
        return children(\.patientId)
    }
    
    var observers: Siblings<Patient, User, UserPatient> {
        return siblings()
    }
}

extension Patient: Parameter {}
extension Patient: SQLiteModel {}

extension Patient: Migration {
    public static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.patientTagId, to: \PatientTag.id)
        }
    }
}


