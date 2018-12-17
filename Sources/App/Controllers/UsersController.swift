//
//  OperatorsController.swift
//  App
//
//  Created by Nikolay Andonov on 2.12.18.
//

import Foundation
import Vapor
import FluentSQLite

class UsersController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let tokenAuthenticationMiddleware = User.tokenAuthMiddleware()
        let authenticatedRoute = router.grouped(tokenAuthenticationMiddleware)
        let userRoute = authenticatedRoute.grouped(Constants.apiRoot, "user")
        userRoute.get("/", use: getUserInfo)
        userRoute.post("subscribe", use: subscribeToPatient)
        userRoute.post("unsubscribe", use: unsubscribeToPatient)
        userRoute.get("subscriptions", use: getPatientSubscriptions)
    }
    
    func getUserInfo(_ request: Request) throws -> Future<User.Public> {
        let user = try request.requireAuthenticated(User.self)
        return Future.map(on: request, {
            return try user.mapToPublic()
        })
    }
    
    func subscribeToPatient(_ request: Request) throws -> Future<HTTPResponse> {
        return try request.content.decode(Patient.Subscribtion.self).flatMap { subscriptionRequest in
            let notFound = Abort(.notFound, reason: "The Provided Patient ID is Invalid")
            let user = try request.requireAuthenticated(User.self)
            return Patient
                .query(on: request)
                .filter(\Patient.id, .equal, subscriptionRequest.patientId)
                .first()
                .unwrap(or: notFound).flatMap{ patient in
                    user.patientSubscriptions.attach(patient, on: request).transform(to: HTTPResponse(status: .created))
            }
        }
    }
    
    func unsubscribeToPatient(_ request: Request) throws -> Future<HTTPResponse> {
        return try request.content.decode(Patient.Subscribtion.self).flatMap { subscriptionRequest in
            let notFound = Abort(.notFound, reason: "The Provided Patient ID is Invalid")
            let user = try request.requireAuthenticated(User.self)
            
            return Patient
                .query(on: request)
                .filter(\Patient.id, .equal, subscriptionRequest.patientId)
                .first()
                .unwrap(or: notFound).flatMap{ patient in
                    user.patientSubscriptions.detach(patient, on: request).transform(to: HTTPResponse(status: .ok))
            }
        }
    }
    
    func getPatientSubscriptions(_ request: Request) throws -> Future<[Patient]> {
        let user = try request.requireAuthenticated(User.self)
        return try user.patientSubscriptions.query(on: request).all()
    }
}
