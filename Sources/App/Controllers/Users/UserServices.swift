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
        return user
            .premise
            .query(on: request)
            .first()
            .map { premise in
                return try user.mapToPublic(premise: premise).parse()
                
        }
    }
    
    class func subscribeToggleForPatient(_ request: Request) throws -> Future<ResultWrapper<Patient.SubscriptionToggleResult>> {
        return try request.content.decode(Patient.Subscribtion.self).flatMap { subscriptionRequest in
            let user = try request.requireAuthenticated(User.self)
            return try user.patientSubscriptions
                .query(on: request)
                .filter(\Patient.id, .equal, subscriptionRequest.patientId)
                .first()
                .flatMap({ patient in
                    if let patient = patient {
                        return try unsubscribeToPatient(patient.requireID(), user: user, request: request).transform(to: Patient.SubscriptionToggleResult(isSubscribed: false, patientId: patient.requireID()).parse())
                    } else {
                        return try subscribeToPatient(subscriptionRequest.patientId, user: user, request: request).transform(to: Patient.SubscriptionToggleResult(isSubscribed: true, patientId: subscriptionRequest.patientId).parse())
                    }
                })
        }
    }
    
    class func subscribeToPatient(_ request: Request) throws -> Future<FormattedResultWrapper> {
        return try request.content.decode(Patient.Subscribtion.self).flatMap { subscriptionRequest in
            let user = try request.requireAuthenticated(User.self)
            return try subscribeToPatient(subscriptionRequest.patientId, user: user, request: request)
        }
    }
    
    class private func subscribeToPatient(_ patientId: Patient.ID, user: User, request: Request) throws -> Future<FormattedResultWrapper> {
        let notFound = Abort(.notFound, reason: "The Provided Patient ID is Invalid")
        return Patient
            .query(on: request)
            .filter(\Patient.id, .equal, patientId)
            .first()
            .unwrap(or: notFound)
            .flatMap{ patient in
                try PatientServices.validateInteraction(for: user, with: patient)
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
    
    class private func unsubscribeToPatient(_ patientId: Patient.ID, user: User, request: Request) throws -> Future<FormattedResultWrapper> {
        let notFound = Abort(.notFound, reason: "The Provided Patient ID is Invalid")
        return try user.patientSubscriptions
            .query(on: request)
            .filter(\Patient.id, .equal, patientId)
            .first()
            .unwrap(or: notFound).flatMap{ patient in
                try PatientServices.validateInteraction(for: user, with: patient)
                return user.patientSubscriptions.detach(patient, on: request).transform(to: FormattedResultWrapper(result: .success))
        }
    }
    
    class func unsubscribeToPatient(_ request: Request) throws -> Future<FormattedResultWrapper> {
        return try request.content.decode(Patient.Subscribtion.self).flatMap { subscriptionRequest in
            let user = try request.requireAuthenticated(User.self)
            return try unsubscribeToPatient(subscriptionRequest.patientId, user: user, request: request)
        }
    }
    
    
    
    class func getPatientSubscriptions(_ request: Request) throws -> Future<ArrayResultWrapper<Patient>> {
        let user = try request.requireAuthenticated(User.self)
        return try user
            .patientSubscriptions
            .query(on: request)
            .filter(\.premiseId == user.premiseId)
            .all()
            .map { patients in
                return patients.parse()
        }
    }
    
    class func saveDeviceToken(_ request: Request) throws -> Future<FormattedResultWrapper> {
        let user = try request.requireAuthenticated(User.self)
        return try request.content.decode(Device.Request.self).flatMap{ deviceRequest in
            return try user.userDevice.query(on: request)
                .first()
                .flatMap { device in
                    if let device = device {
                        device.deviceToken = deviceRequest.deviceToken
                        return device.update(on: request).transform(to: FormattedResultWrapper(result: .success))
                    }
                    let model = deviceRequest.model()
                    try model.userId = user.requireID()
                    return model.save(on: request).transform(to: FormattedResultWrapper(result: .success))
            }
        }
    }
    
    //MARK: - Web Services
    
    
    
}
