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
    
    class func createHealthRecord(request: Request, recordRequest: HealthRecord.Request) throws -> Future<ResultParser<HealthRecord.Public>> {
        let user = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            let record = try recordRequest.model(with: patient.requireID())
            try record.userId = user.requireID()
            return record.save(on: request).map{ _ in
                try record.mapToPublic(creator: user).parse()
            }
        }
    }
    
    class func getHealthRecords(request: Request) throws -> Future<ArrayResultParser<HealthRecord.Public>> {
        _ = try request.requireAuthenticated(User.self)
        //TODO: Currently if the user get deleted the health record won't be fetched
        return try request.parameters.next(Patient.self).flatMap { patient in
            try patient.healthRecords
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
    
    class func updateHealthRecord(request: Request, recordRequest: HealthRecord.Request)throws -> Future<HTTPStatus> {
        _ = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            
            guard let healthRecordId = recordRequest.id else {
                throw Abort(.badRequest, reason: "Missing Health Record Id")
            }
            let notFound = try Abort(.notFound, reason: "No record with ID '\(healthRecordId)' found for patient '\(patient.requireID())'")
            
            return try patient.healthRecords.query(on: request).filter(\.id == healthRecordId).first().unwrap(or: notFound).flatMap({ record  in
                return try recordRequest
                    .model(with: patient.requireID())
                    .update(on: request)
                    .transform(to: .ok)
            })
        }
    }
    
    class func deleteRecord(request: Request) throws -> Future<HTTPStatus> {
        _ = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            let healthRecordId = try request.parameters.next(HealthRecord.ID.self)
            return try patient.healthRecords
                .query(on: request)
                .filter(\.id == healthRecordId).first().unwrap(or: Abort(.notFound, reason: "Health Record Doesn't Exists"))
                .delete(on: request)
                .transform(to: .noContent)
        }
    }
    
}
