//
//  UserServices.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL

class UserServices {
    
    //MARK: - Client Services
    
    class func getUserInfo(_ request: Request) throws -> Future<ResultWrapper<User.Public>> {
        let user = try request.requireAuthenticated(User.self)
        return Future.map(on: request, {
            return try user.mapToPublic().parse()
        })
    }
    
    class func subscribeToPatient(_ request: Request) throws -> Future<FormattedResultWrapper> {
        return try request.content.decode(Patient.Subscribtion.self).flatMap { subscriptionRequest in
            let notFound = Abort(.notFound, reason: "The Provided Patient ID is Invalid")
            let user = try request.requireAuthenticated(User.self)
            return Patient
                .query(on: request)
                .filter(\Patient.id, .equal, subscriptionRequest.patientId)
                .first()
                .unwrap(or: notFound).flatMap{ patient in
                    
                    return try user.patientSubscriptions.query(on: request)
                        .filter(\.id == patient.requireID())
                        .first()
                        .flatMap({ existingSubscriber in
                            if let _ = existingSubscriber {
                                return Future.map(on: request, {
                                    return FormattedResultWrapper(result: .success)
                                })
                            }
                            return user.patientSubscriptions.attach(patient, on: request).transform(to: FormattedResultWrapper(result: .success))
                        })
            }
        }
    }
    
    class func unsubscribeToPatient(_ request: Request) throws -> Future<FormattedResultWrapper> {
        return try request.content.decode(Patient.Subscribtion.self).flatMap { subscriptionRequest in
            let notFound = Abort(.notFound, reason: "The Provided Patient ID is Invalid")
            let user = try request.requireAuthenticated(User.self)
            
            return try user.patientSubscriptions
                .query(on: request)
                .filter(\Patient.id, .equal, subscriptionRequest.patientId)
                .first()
                .unwrap(or: notFound).flatMap{ patient in
                    user.patientSubscriptions.detach(patient, on: request).transform(to: FormattedResultWrapper(result: .success))
            }
        }
    }
    
    class func getPatientSubscriptions(_ request: Request) throws -> Future<ArrayResultWrapper<Patient>> {
        let user = try request.requireAuthenticated(User.self)
        return try user
            .patientSubscriptions
            .query(on: request)
            .all()
            .map { patients in
                return patients.parse()
        }
    }
    
    class func saveDeviceToken(_ request: Request) throws -> Future<HTTPStatus> {
        let user = try request.requireAuthenticated(User.self)
        return try request.content.decode(Device.Request.self).flatMap{ deviceRequest in
            return try user.userDevice.query(on: request)
                .first()
                .flatMap { device in
                    if let device = device {
                        device.deviceToken = deviceRequest.deviceToken
                        return device.update(on: request).transform(to: .ok)
                    }
                    let model = deviceRequest.model()
                    try model.userId = user.requireID()
                    return model.save(on: request).transform(to: .ok)
            }
        }
    }
    
    //MARK: - Web Services
    
    
    
}
