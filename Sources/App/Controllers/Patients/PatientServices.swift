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
    
    class func cretePatient(_ request: Request, patientRequest: Patient.Public) throws -> Future<Patient.Public> {
        _ = try request.requireAuthenticated(User.self)
        
        return Patient
            .query(on: request)
            .filter(\Patient.personalIdentification == patientRequest.personalIdentification)
            .first()
            .flatMap { patient -> Future<Patient.Public> in
                if let _ = patient {
                    throw Abort(.badRequest, reason: "Patient with the provided personal identification already exists.")
                }
                return patientRequest.privateModel()
                    .save(on: request)
                    .map{ privateModel in
                        return try privateModel.mapToPublic()
                }
        }
    }
    
    class func updatePatient(_ request: Request, patientRequest: Patient.Public) throws -> Future<HTTPStatus> {
        _ = try request.requireAuthenticated(User.self)
        return patientRequest
            .privateModel()
            .update(on: request)
            .transform(to: .ok)
    }
    
    class func getPatient(_ request: Request) throws -> Future<Patient.Public> {
        _ = try request.requireAuthenticated(User.self)
        return try request
            .parameters
            .next(Patient.self).map{ patient in
                try patient.mapToPublic()
        }
    }
    
    class func getAllPatients(_ request: Request) throws -> Future<[Patient.Public]> {
        _ = try request.requireAuthenticated(User.self)
        return Patient
            .query(on: request)
            .all()
            .map {
               try $0.map { try $0.mapToPublic() }
        }
    }
    
    
    class func deletePatient(_ request: Request) throws -> Future<HTTPStatus> {
        _ = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self)
            .flatMap({ patient  in
                try patient.healthRecords
                    .query(on: request)
                    .delete()
                    .flatMap { _ in
                        return try patient.observers.detachAll(on: request)
                            .and(patient.delete(on: request))
                            .and(PatientTagServices.unassignPatientTag(for: patient, on: request))
                            .catchMap({ error in
                                if let error = error as? AbortError, error.status == .notFound {
                                    //Disregard this case since there were no associated tags
                                    return (((),()),.ok)
                                }
                                throw error
                            })
                        
                }
            }).transform(to: .ok)
    }
    
    class func searchPatients(_ request: Request) throws -> Future<[Patient.Public]> {
        _ = try request.requireAuthenticated(User.self)
        guard let searchQuery = request.query[String.self, at: "search"] else {
            throw Abort(.badRequest, reason: "Missing search query")
        }
        
//        if searchQuery.count < 4 {
//            return Future.map(on: request) { return [] }
//        }
        
        return request.withNewConnection(to: .psql) { connection in
            return connection
                .raw("SELECT * FROM \"Patient\" WHERE LOWER(\"fullName\") LIKE LOWER('%\(searchQuery)%')")
                .all(decoding: Patient.self)
            } .map { patients in
                return try patients.map { try $0.mapToPublic() }
        }
    }
    
    //MARK: - Web Services
    
    class func renderPatientsList(_ request: Request) throws -> Future<View> {
        _ = try request.requireAuthenticated(User.self)
        return Patient
            .query(on: request)
            .sort(\.fullName)
            .all()
            .flatMap { patients in
                let context = ["patients": patients]
                return try request.view().render("patients-list", context)
        }
    }
}
