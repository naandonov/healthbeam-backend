//
//  Patient.swift
//  App
//
//  Created by Nikolay Andonov on 3.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class Patient: Content {
    
    struct Subscribtion: Content {
        var patientId: Int
    }
    
    struct Public: Content {
        var id: Int?
        var fullName: String
        var gender: String
        var personalIdentification: String
        var birthDate: Date
        var bloodType: String
        var alergies: [String]
        var premiseLocation: String
//        var patientTag: PatientTag.Public?
//        var healthRecords: [HealthRecord.Public]?
        
        func creationModel(premiseId: Premise.ID) -> Patient {
            return Patient(id: id,
                           fullName: fullName,
                           gender: gender,
                           personalIdentification: personalIdentification,
                           birthDate: birthDate,
                           bloodType: bloodType,
                           alergies: alergies,
                           premiseLocation: premiseLocation,
                           premiseId: premiseId)
        }
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
    
    var premiseId: Premise.ID
    
    
    init(id: Int? = nil, fullName: String, gender: String, personalIdentification: String, birthDate: Date, bloodType: String, alergies: [String], premiseLocation: String, premiseId: Premise.ID) {
        
        self.fullName = fullName
        self.gender = gender
        self.personalIdentification = personalIdentification
        self.birthDate = birthDate
        self.bloodType = bloodType
        self.alergies = alergies
        self.premiseLocation = premiseLocation
        self.premiseId = premiseId
    }
    
    func updateFromPublic(_ publicPatient: Public) {
       fullName = publicPatient.fullName
       gender = publicPatient.gender
       personalIdentification = publicPatient.personalIdentification
       birthDate = publicPatient.birthDate
       bloodType = publicPatient.bloodType
       alergies = publicPatient.alergies
       premiseLocation = publicPatient.premiseLocation
    }
}

extension Patient: PublicMapper {
    typealias PublicElement = Patient.Public
    
    func mapToPublic() throws -> Patient.Public {
        return try Patient.Public(id: requireID(),
                                  fullName: fullName,
                                  gender: gender,
                                  personalIdentification: personalIdentification,
                                  birthDate: birthDate,
                                  bloodType: bloodType,
                                  alergies: alergies,
                                  premiseLocation: premiseLocation)
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
    
    var premise: Parent<Patient, Premise> {
        return parent(\.premiseId)
    }
}

extension Patient: Parameter {}
extension Patient: PostgreSQLModel {}

extension Patient: Migration {
//    public static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            builder.reference(from: \.patientTagId, to: \PatientTag.id)
//        }
//    }
}


