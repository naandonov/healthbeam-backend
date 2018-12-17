//
//  HealthRecordsController.swift
//  App
//
//  Created by Nikolay Andonov on 8.12.18.
//

import Foundation
import FluentSQLite
import Vapor

class HealthRecordsController: RouteCollection {
    func boot(router: Router) throws {
        
        let tokenAuthenticationMiddleware = User.tokenAuthMiddleware()
        let authorizedRoute = router.grouped(tokenAuthenticationMiddleware)
        let healthRecordsRoute = authorizedRoute.grouped(Constants.apiRoot, "patients", Patient.parameter, "healthRecords")
        
        healthRecordsRoute.post(HealthRecord.Request.self, use: createHealthRecord)
        healthRecordsRoute.get(use: getHealthRecords)
        healthRecordsRoute.put(HealthRecord.Request.self, at: "/", use: updateHealthRecord)
        healthRecordsRoute.delete(HealthRecord.ID.parameter, use: deleteRecord)
        
    }
    
    func createHealthRecord(request: Request, recordRequest: HealthRecord.Request) throws -> Future<HealthRecord> {
        _ = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            try recordRequest
                .model(with: patient.requireID())
                .save(on: request)
        }
    }
    
    func getHealthRecords(request: Request) throws -> Future<[HealthRecord]> {
        _ = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            try patient.healthRecords
                .query(on: request)
                .all()
        }
    }
    
    func updateHealthRecord(request: Request, recordRequest: HealthRecord.Request)throws -> Future<HTTPStatus> {
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
    
    func deleteRecord(request: Request) throws -> Future<HTTPStatus> {
        _ = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            let healthRecordId = try request.parameters.next(HealthRecord.ID.self)
            return try patient.healthRecords
                .query(on: request)
                .filter(\.id == healthRecordId)
                .delete()
                .transform(to: .noContent)
        }
    }
}
