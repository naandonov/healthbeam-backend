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
    
    class func getUserInfo(_ request: Request) throws -> Future<User.Public> {
        let user = try request.requireAuthenticated(User.self)
        return Future.map(on: request, {
            return try user.mapToPublic()
        })
    }
    
    class func subscribeToPatient(_ request: Request) throws -> Future<HTTPResponse> {
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
                                    return HTTPResponse(status: .ok)
                                })
                            }
                            return user.patientSubscriptions.attach(patient, on: request).transform(to: HTTPResponse(status: .created))
                        })
            }
        }
    }
    
    class func unsubscribeToPatient(_ request: Request) throws -> Future<HTTPResponse> {
        return try request.content.decode(Patient.Subscribtion.self).flatMap { subscriptionRequest in
            let notFound = Abort(.notFound, reason: "The Provided Patient ID is Invalid")
            let user = try request.requireAuthenticated(User.self)
            
            return try user.patientSubscriptions
                .query(on: request)
                .filter(\Patient.id, .equal, subscriptionRequest.patientId)
                .first()
                .unwrap(or: notFound).flatMap{ patient in
                    user.patientSubscriptions.detach(patient, on: request).transform(to: HTTPResponse(status: .ok))
            }
        }
    }
    
    class func getPatientSubscriptions(_ request: Request) throws -> Future<[Patient]> {
        let user = try request.requireAuthenticated(User.self)
        return try user.patientSubscriptions.query(on: request).all()
    }
    
    //MARK: - Web Services
    
    
    
}
