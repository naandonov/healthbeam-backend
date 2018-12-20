//
//  PatientServices.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL

class PatientServices {
    
    class func deletePatient(_ request: Request) throws -> Future<HTTPStatus> {
        _ = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self)
            .flatMap({ patient  in
                try patient
                    .healthRecords
                    .query(on: request)
                    .delete()
                    .flatMap { _ in
                        return try patient.observers.detachAll(on: request)
                            .and(patient.delete(on: request))
                            .and(PatientTagServices.unassignPatientTag(for: patient, on: request))
                }
            }).transform(to: .ok)
    }
    
    class func searchPatients(_ request: Request) throws -> Future<[Patient.Public]> {
        _ = try request.requireAuthenticated(User.self)
        guard let searchQuery = request.query[String.self, at: "search"] else {
            throw Abort(.badRequest, reason: "Missing search query")
        }
        
        return request.withPooledConnection(to: .psql) { conn in
            return conn.raw("SELECT * FROM patients")
                .all(decoding: Patient.self)
            }.map { patients in
                return try patients.map { try $0.mapToPublic()}
        }
        
//        return Patient.query(on: request)
////            .filter(custom: SQLiteExpression)
////            .filter(custom: SQLiteExpression)
//            .filter(\Patient.fullName, .like, searchQuery)
//            .all()
//            .map { patients in
//                try patients.map { try $0.mapToPublic()
//                }
//        }
    }
    
    //MARK: - Web Services
    
    class func renderPatientsList(_ request: Request) throws -> Future<View> {
        _ = try request.requireAuthenticated(User.self)
        return Patient.query(on: request)
            .sort(\.fullName)
            .all()
            .flatMap { patients in
                let context = ["patients": patients]
                return try request.view().render("patients-list", context)
        }
    }
}
