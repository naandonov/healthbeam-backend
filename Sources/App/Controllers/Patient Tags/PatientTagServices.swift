//
//  PateintTagServices.swift
//  App
//
//  Created by Nikolay Andonov on 13.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL

class PatientTagServices {
    
    
    class func assignPatientTag(request: Request, patientTag: PatientTag) throws -> Future<PatientTag> {
        _ = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            PatientTag.query(on: request)
                .filter(\.major == patientTag.major)
                .filter(\.minor == patientTag.minor)
                .first()
                .flatMap({ existingPatientTag in
                    if let existingPatientTag = existingPatientTag {
                        existingPatientTag.patientId = patient.id
                        return existingPatientTag.update(on: request)
                    }
                    else {
                        patientTag.patientId = patient.id
                        return patientTag.save(on: request).flatMap({ _ in
                            patient.patientTagId = patientTag.id
                            return patient.update(on: request).map({ _ -> PatientTag in
                                patientTag
                            })
                        })
                    }
                })
        }
    }
    
    class func unassignPatientTag(request: Request) throws -> Future<HTTPStatus> {
        _ = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            return try unassignPatientTag(for: patient, on: request)
        }
    }
    
    class func unassignPatientTag(for patient: Patient, on request: Request) throws -> Future<HTTPStatus> {
        let notFound = Abort(.badRequest, reason: "The Specified Patient doesn't have an associated Tag")
        return try patient.patientTag.query(on: request).first()
            .unwrap(or: notFound)
            .delete(on: request)
            .flatMap { _ in
                patient.patientTagId = nil
                return patient.update(on: request)
                    .flatMap({ _ -> Future<HTTPStatus> in
                        return try PatientAlert
                            .query(on: request)
                            .filter(\.patientId == patient.requireID())
                            .first()
                            .flatMap({ patientAlert in
                                if let patientAlert = patientAlert {
                                    return patientAlert.delete(on: request).transform(to: HTTPStatus.ok)
                                }
                                return Future.map(on: request, {
                                    HTTPStatus.ok
                                })
                            })
                    })
        }
    }
    
    class func getPatientTag(request: Request) throws -> Future<PatientTag> {
        _ = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            let notFound = Abort(.badRequest, reason: "The Specified Patient doesn't have an associated Tag")
            return try patient.patientTag
                .query(on: request)
                .first()
                .unwrap(or: notFound)
        }
    }
}
