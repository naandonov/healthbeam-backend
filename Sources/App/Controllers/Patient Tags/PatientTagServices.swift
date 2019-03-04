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
    
    
    class func assignPatientTag(request: Request, patientTag: PatientTag) throws -> Future<ResultWrapper<PatientTag.Public>> {
        let user = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            try PatientServices.validateInteraction(for: user, with: patient)
            return PatientTag.query(on: request)
                .filter(\.major == patientTag.major)
                .filter(\.minor == patientTag.minor)
                .join(\Patient.id, to: \PatientTag.patientId)
                .filter(\Patient.premiseId == user.premiseId)
                .first()
                .flatMap({ existingPatientTag in
                    if let existingPatientTag = existingPatientTag {
                        existingPatientTag.patientId = patient.id
                        return existingPatientTag.update(on: request).map({ tag in
                            try tag.mapToPublic().parse()
                        })
                    } else {
                        return try patient.patientTag.query(on: request).first().flatMap({ tag ->  Future<ResultWrapper<PatientTag.Public>> in
                            if let unwrappedTag = tag {
                                unwrappedTag.minor = patientTag.minor
                                unwrappedTag.major = patientTag.major
                                return unwrappedTag.update(on: request).map({ tag in
                                    try tag.mapToPublic().parse()
                                })
                            }
                            patientTag.patientId = patient.id
                            return patientTag.save(on: request).flatMap({ tag in
                                patient.patientTagId = patientTag.id
                                return patient.update(on: request).transform(to: try tag.mapToPublic().parse())
                            })
                        })
                    }
                })
        }
    }
    
    class func unassignPatientTag(request: Request) throws -> Future<FormattedResultWrapper> {
        let user = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            try PatientServices.validateInteraction(for: user, with: patient)
            return try unassignPatientTag(for: patient, on: request).transform(to: FormattedResultWrapper(result: .success))
        }
    }
    
    class func unassignPatientTag(for patient: Patient, on request: Request) throws -> Future<HTTPStatus> {
        let notFound = Abort(.notFound, reason: "The Specified Patient doesn't have an associated Tag")
        
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
                                    let patientObservers = try patient
                                        .observers
                                        .query(on: request)
                                        .all()
                                    
                                    return patientAlert
                                        .delete(on: request)
                                        .and(patientObservers)
                                        .flatMap{ parameters -> Future<HTTPStatus> in
                                            return try AlertServices.dispatchNotificationsForObservers(observers: parameters.1,
                                                                                         isSilentPush: true,
                                                                                         extra: patientAlert.notificationExtra,
                                                                                         request: request,
                                                                                         eventLoop: patientObservers.eventLoop)
                                                .transform(to: HTTPStatus.ok)
                                    }
                                }
                                return Future.map(on: request, {
                                    HTTPStatus.ok
                                })
                            })
                    })
        }
    }
    
    class func getPatientTag(request: Request) throws -> Future<PatientTag> {
        let user = try request.requireAuthenticated(User.self)
        return try request.parameters.next(Patient.self).flatMap { patient in
            try PatientServices.validateInteraction(for: user, with: patient)
            let notFound = Abort(.badRequest, reason: "The Specified Patient doesn't have an associated Tag")
            return try patient.patientTag
                .query(on: request)
                .first()
                .unwrap(or: notFound)
        }
    }
}
