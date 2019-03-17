//
//  PatientTag.swift
//  App
//
//  Created by Nikolay Andonov on 13.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class PatientTag: Content {
    
    struct Public: Content {
        var id: Int?
        var minor: Int
        var major: Int
        
        var representationName: String {
            return "\(minor)-\(major)"
        }
    }
    
    var id: Int?
    var minor: Int
    var major: Int
    
    var patientId: Patient.ID?
    
    init(minor: Int, major: Int) {
        self.minor = minor
        self.major = major
    }
    
    func mapToPublic() throws -> Public {
        return try Public(id: requireID(), minor: minor, major: major)
    }
}

extension PatientTag {
    var patient: Parent<PatientTag, Patient>? {
        return parent(\.patientId)
    }
}

extension PatientTag: Migration {
//    public static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            builder.reference(from: \.patientId, to: \Patient.id)
//        }
//    }
}

extension PatientTag: Parameter {}
extension PatientTag: PostgreSQLModel {}

