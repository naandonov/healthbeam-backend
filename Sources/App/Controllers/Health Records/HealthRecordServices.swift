//
//  HealthRecordServices.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL

class HealthRecordServices {
    
    class func createHealthRecord(request: Request, recordRequest: HealthRecord.Public) throws -> Future<ResultWrapper<HealthRecord.Public>> {
        let user = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            try PatientServices.validateInteraction(for: user, with: patient)
            let record = try recordRequest.creationModel(with: patient.requireID())
            try record.userId = user.requireID()
            return record.save(on: request).map{ _ in
                try record.mapToPublic(creator: user).parse()
            }
        }
    }
    
    class func getHealthRecords(request: Request) throws -> Future<ArrayResultWrapper<HealthRecord.Public>> {
        let user = try request.requireAuthenticated(User.self)
        //TODO: Currently if the user get deleted the health record won't be fetched
        return try request.parameters.next(Patient.self).flatMap { patient in
            try PatientServices.validateInteraction(for: user, with: patient)
            return try patient.healthRecords
                .query(on: request)
                .join(\User.id, to: \HealthRecord.userId)
                .alsoDecode(User.self)
                .all()
                .map({ joinedTable in
                    return try joinedTable.map {
                        let record = $0.0
                        return try record.mapToPublic(creator: $0.1)
                        }.parse()
                })
        }
    }
    
    class func updateHealthRecord(request: Request, recordRequest: HealthRecord.Public)throws -> Future<FormattedResultWrapper> {
        let user = try request.requireAuthenticated(User.self)
        guard let healthRecordId = recordRequest.id else {
            throw Abort(.badRequest, reason: "Missing Health Record Id")
        }
        
        return  HealthRecord
            .query(on: request)
            .filter(\.id == healthRecordId).first().unwrap(or: Abort(.notFound, reason: "Health Record Doesn't Exists"))
            .flatMap { healthRecord in
                return Patient
                    .query(on: request)
                    .filter(\Patient.id == healthRecord.patientId)
                    .first().unwrap(or: Abort(.notFound, reason: "Health Record Doesn't Have An Owner"))
                    .flatMap { patient in
                        try PatientServices.validateInteraction(for: user, with: patient)
                         healthRecord.updateFromPublic(recordRequest)
                        return healthRecord
                            .update(on: request)
                            .map { _ in
                                return FormattedResultWrapper(result: .success)
                        }
                }
        }
    }
    
    class func deleteRecord(request: Request) throws -> Future<FormattedResultWrapper> {
        let user = try request.requireAuthenticated(User.self)
        let healthRecordId = try request.parameters.next(HealthRecord.ID.self)
        
        
        return  HealthRecord
            .query(on: request)
            .filter(\.id == healthRecordId).first().unwrap(or: Abort(.notFound, reason: "Health Record Doesn't Exists"))
            .flatMap { healthRecord in
                return Patient
                    .query(on: request)
                    .filter(\Patient.id == healthRecord.patientId)
                    .first().unwrap(or: Abort(.notFound, reason: "Health Record Doesn't Have An Owner"))
                    .flatMap { patient in
                        try PatientServices.validateInteraction(for: user, with: patient)
                        return healthRecord
                            .delete(on: request)
                            .map { _ in
                                return FormattedResultWrapper(result: .success)
                        }
                }
        }
    }
}
