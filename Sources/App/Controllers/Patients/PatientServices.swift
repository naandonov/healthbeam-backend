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
    
    class func cretePatient(_ request: Request, patientRequest: Patient.Public) throws -> Future<ResultWrapper<Patient.Public>> {
        let user = try request.requireAuthenticated(User.self)
        return Patient
            .query(on: request)
            .filter(\Patient.personalIdentification == patientRequest.personalIdentification)
            .first()
            .flatMap { patient in
                if let _ = patient {
                    throw Abort(.badRequest, reason: "Patient with the provided personal identification already exists.")
                }
                let privatePatient = patientRequest.creationModel(premiseId: user.premiseId)

                return privatePatient
                    .save(on: request)
                    .flatMap{ privateModel in
                        user.patientSubscriptions.attach(privatePatient, on: request).map({ _ in
                            return try privateModel.mapToPublic().parse()
                        })
                }
        }
    }
    
    class func updatePatient(_ request: Request, patientRequest: Patient.Public) throws -> Future<ResultWrapper<Patient.Public>> {
        let user = try request.requireAuthenticated(User.self)
        return accessiblePatients(on: request, for: user)
            .filter(\.id == patientRequest.id)
            .first()
            .unwrap(or: Abort(.notFound, reason:"Patient does not exist")).flatMap { patient in
                try validateInteraction(for: user, with: patient)
                patient.updateFromPublic(patientRequest)
                return patient
                    .update(on: request)
                    .map({ patient in
                        return try patient.mapToPublic().parse()
                    })
        }
    }
    
    class func getPatient(_ request: Request) throws -> Future<Patient.Public> {
        let user = try request.requireAuthenticated(User.self)
        return try request
            .parameters
            .next(Patient.self).map{ patient in
                try validateInteraction(for: user, with: patient)
                return try patient.mapToPublic()
        }
    }
    
    class func getAllPatients(_ request: Request) throws -> Future<[Patient.Public]> {
        let user = try request.requireAuthenticated(User.self)
        return accessiblePatients(on: request, for: user)
            .all()
            .map {
                try $0.map { try $0.mapToPublic() }
        }
    }
    
    
    class func deletePatient(_ request: Request) throws -> Future<FormattedResultWrapper> {
        let user = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self)
            .flatMap({ patient  in
                try validateInteraction(for: user, with: patient)
                return try patient.healthRecords
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
                        
                    }.transform(to: FormattedResultWrapper(result: .success))
            })
    }
    
    class func getPatientAttributes(_ request: Request) throws -> Future<ResultWrapper<PatientAttributes>> {
        let user = try request.requireAuthenticated(User.self)
        return try request
            .parameters
            .next(Patient.self).flatMap{ patient in
                try validateInteraction(for: user, with: patient)
                return try patient
                    .healthRecords
                    .query(on: request)
                    .join(\HealthRecord.userId, to: \User.id)
                    .alsoDecode(User.self)
                    .all()
                    .flatMap { healthRecordsTable in
                        
                        try patient
                            .patientTag
                            .query(on: request)
                            .first().flatMap { patientTag in
                                try patient
                                    .observers
                                    .query(on: request)
                                    .all()
                                    .map { observers -> ResultWrapper<PatientAttributes> in
                                        let patientAttributes = PatientAttributes(observers: try observers.map { try $0.mapToExternalPublic() },
                                                                                  healthRecords: try healthRecordsTable.map { try $0.0.mapToPublic(creator: $0.1) },
                                                                                  patientTag: try patientTag.map { try $0.mapToPublic()} )
                                        return patientAttributes.parse()
                                }
                        }
                }
        }
    }
    
    //    class func searchPatients(_ request: Request) throws -> Future<[Patient.Public]> {
    //        _ = try request.requireAuthenticated(User.self)
    //        guard let searchQuery = request.query[String.self, at: "search"] else {
    //            throw Abort(.badRequest, reason: "Missing search query")
    //        }
    //
    ////        if searchQuery.count < 4 {
    ////            return Future.map(on: request) { return [] }
    ////        }
    //
    //        return request.withNewConnection(to: .psql) { connection in
    //            return connection
    //                .raw("SELECT * FROM \"Patient\" WHERE LOWER(\"fullName\") LIKE LOWER('%\(searchQuery)%')")
    //                .all(decoding: Patient.self)
    //            } .map { patients in
    //                return try patients.map { try $0.mapToPublic() }
    //        }
    //    }
    
    //MARK: - Web Services
    
    class func renderPatientsList(_ request: Request) throws -> Future<View> {
        let user = try request.requireAuthenticated(User.self)
        return accessiblePatients(on: request, for: user)
            .sort(\Patient.fullName)
            .all()
            .flatMap { patients -> Future<View> in
                let context = ["patients": patients]
                return try request.view().render("patients-list", context)
        }
    }
}

//MARK: - Utilitites

extension PatientServices {
    
    class func validateInteraction(for user: User, with patient: Patient) throws {
        if user.premiseId != patient.premiseId {
            throw Abort(.methodNotAllowed, reason: "Unable to interact with patients outside of your premise")
        }
    }
    
    class func accessiblePatients(on request: Request, for user: User) -> QueryBuilder<PostgreSQLDatabase, Patient> {
        return Patient
            .query(on: request)
            .filter(\.premiseId == user.premiseId)
    }
}
