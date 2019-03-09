//
//  AlertServices.swift
//  App
//
//  Created by Nikolay Andonov on 14.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Crypto

class AlertServices {
    
    //MARK: - Client Services
    
    class func createAlert(_ request: Request, encoding: PatientAlert.Encoded) throws -> Future<HTTPStatus> {
        
        guard let encryptedData = Data.init(fromHexEncodedString: encoding.value) else {
            throw Abort(.badRequest, reason:"Missing Ecnrypted Data")
        }

        let privateKey = try FileManager.shared.privateKeyContent()
        let decryptedData = try RSA.decrypt(encryptedData, padding: .pkcs1, key: .private(pem: privateKey))

        guard let decryptedString = String(data: decryptedData, encoding: .utf8),
            decryptedString.split(separator: "&").count == 4 else {
                throw Abort(.badRequest, reason:"Invalid request")
        }

        let decryptedValues = decryptedString.split(separator: "&")
        let requestTimeInterval = TimeInterval(decryptedValues[0])!
        let minor = Int(decryptedValues[1])!
        let major = Int(decryptedValues[2])!
        let gatewayIdentifier = String(decryptedValues[3])

        if (Date().timeIntervalSince1970 - requestTimeInterval) > 10 {
            throw Abort(.badRequest, reason:"Invalid request")
        }

        return Gateway.query(on: request)
            .filter(\Gateway.codeIdentifier, .equal, gatewayIdentifier)
            .first()
            .unwrap(or: Abort(.badRequest, reason:"Invalid Gateway Code Identifier")).flatMap({ gateway in

                let notAssociatedTag = Abort(.notFound, reason: "No patient is associated with this tag")
                return PatientTag.query(on: request)
                    .filter(\PatientTag.minor, .equal, minor)
                    .filter(\PatientTag.major, .equal, major)
                    .first()
                    .unwrap(or: notAssociatedTag)
                    .flatMap({ patientTag in
                        guard let patient = patientTag.patient else {
                            throw notAssociatedTag
                        }
                        
                        return patient
                            .query(on: request)
                            .first()
                            .unwrap(or: notAssociatedTag)
                            .flatMap({ patient in
                                
                                return try PatientAlert.query(on: request)
                                    .filter(\.status == AlertStatus.pending.rawValue)
                                    .filter(\.patientId == patient.requireID())
                                    .first().flatMap({ alert in
                                        
                                        if let _ = alert {
                                            throw Abort(.notFound, reason: "There is an existing pending alert for the specified patient.")
                                        }
                                        
                                        let newAlert = try PatientAlert(creationDate: Date(), alertStatus: .pending, gatewayId: gateway.requireID())
                                        try newAlert.patientId = patient.requireID()
                                        
                                        let patientObservers = try patient
                                            .observers
                                            .query(on: request)
                                            .all()
                                        
                                        return newAlert
                                            .save(on: request)
                                            .and(patientObservers)
                                            .flatMap({ parameters -> Future<Void> in
                                                
                                                return try dispatchNotificationsForObservers(observers: parameters.1,
                                                                                             title: "Patient Alert",
                                                                                             body: "\(patient.fullName) needs immediate assistance from \(gateway.name)",
                                                    extra: parameters.0.notificationExtra,
                                                    request: request,
                                                    eventLoop: patientObservers.eventLoop)
                                                
                                                
                                            }).transform(to: HTTPStatus.ok)
                                    })
                            })
                    })
            })
    }
    
  
    
    class func dispatchNotificationsForObservers(observers: [User], isSilentPush: Bool = false, title: String? = nil, body: String? = nil, extra: [String: String] = [:], request: Request, eventLoop: EventLoop) throws -> Future<Void> {
        var chainedResponse: [Future<Void>] = []
        for user in observers {
            
            let pendingAlerts = try getPendingAlertsCount(request, user: user)
                .flatMap{ alertsCount -> Future<Void> in
                    try user
                        .userDevice
                        .query(on: request)
                        .first()
                        .flatMap{ device -> Future<Void> in
                            if let device = device {
                                
                                let payload: APNSPayload
                                if let title = title, let body = body, !isSilentPush {
                                    payload = APNSPayload(title: title,
                                                          body: body)
                                    payload.sound = "alarm.wav"
                                } else {
                                    payload = APNSPayload()
                                    payload.contentAvailable = true
                                }
                                payload.badge = alertsCount.result?.count
                                payload.extra = extra
                                return try ServiceUtilities.pushToDeviceToken(device.deviceToken, payload, request).transform(to: ())
                            }
                            return Future.map(on: request) { }
                    }
            }
            chainedResponse.append(pendingAlerts)
        }
        return Future<Void>.andAll(chainedResponse, eventLoop: eventLoop)
    }
    
    class func respondToAlert(_ request: Request, subscription: Patient.Respond) throws -> Future<FormattedResultWrapper> {
        let user = try request.requireAuthenticated(User.self)
        let notFound = Abort(.notFound, reason: "No alert exists for the subscribed patients")
        return try user.patientSubscriptions
            .query(on: request)
            .filter(\.id == subscription.patientId)
            .first()
            .unwrap(or: notFound).flatMap({ (patient: Patient) in
                try PatientServices.validateInteraction(for: user, with: patient)
                return PatientAlert
                    .query(on: request)
                    .join(\Patient.id, to: \PatientAlert.patientId)
                    .filter(\PatientAlert.status == AlertStatus.pending.rawValue)
                    .first()
                    .flatMap({ (alert: PatientAlert?) -> Future<Void> in
                        guard let alert = alert else {
                            throw notFound
                        }
                        alert.respondDate = Date()
                        alert.status = AlertStatus.responded.rawValue
                        alert.responderId = try user.requireID()
                        alert.notes = subscription.notes
                        
                        let patientObservers = try patient
                            .observers
                            .query(on: request)
                            .all()
                        
                        return alert.update(on: request)
                            .and(patientObservers)
                            .flatMap{ (_, observers) -> Future<Void> in
                                return try dispatchNotificationsForObservers(observers: observers,
                                                                             isSilentPush: true,
                                                                             extra: alert.notificationExtra,
                                                                             request: request,
                                                                             eventLoop: patientObservers.eventLoop)
                        }
                    })
                    .transform(to: FormattedResultWrapper(result: .success))
            })
    }
    
    class func getPendingAlertsCount(_ request: Request) throws -> Future<ResultWrapper<PatientAlert.Details>> {
        let user = try request.requireAuthenticated(User.self)
        return try getPendingAlertsCount(request, user: user)
    }
    
    private class func getPendingAlertsCount(_ request: Request, user: User) throws -> Future<ResultWrapper<PatientAlert.Details>> {
        return try user.patientSubscriptions
            .query(on: request)
            .join(\PatientAlert.patientId, to: \Patient.id)
            .filter(\PatientAlert.status == AlertStatus.pending.rawValue)
            .count()
            .map { count in
                return PatientAlert.Details(count: count).parse()
        }
    }
    
    private class func getPendingAlerts(_ request: Request, user: User) throws -> Future<ArrayResultWrapper<PatientAlert.Record>> {
        return try user.patientSubscriptions
            .query(on: request)
            .join(\PatientAlert.patientId, to: \Patient.id)
            .alsoDecode(PatientAlert.self)
            .filter(\PatientAlert.status == AlertStatus.pending.rawValue)
            .join(\Gateway.id, to: \PatientAlert.gatewayId)
            .alsoDecode(Gateway.self)
            .join(\Premise.id, to: \Gateway.premiseId)
            .alsoDecode(Premise.self)
            .join(\PatientTag.patientId, to: \Patient.id)
            .alsoDecode(PatientTag.self)
            .sort(\PatientAlert.creationDate, .descending)
            .all()
            .map({ joinedTables in
                try joinedTables.map {
                    try PatientAlert.Record(patientAlert: $0.0.0.0.1,
                                            patient: $0.0.0.0.0,
                                            gateway: $0.0.0.1,
                                            premise: $0.0.1,
                                            patientTag: $0.1)
                    }.parse()
            })
    }
    
    class func getPendingAlerts(_ request: Request) throws -> Future<ArrayResultWrapper<PatientAlert.Record>> {
        let user = try request.requireAuthenticated(User.self)
        return try getPendingAlerts(request, user: user)
    }
    
    class func getAllCompletedAlertRecords(_ request: Request) throws -> Future<ArrayResultWrapper<PatientAlert.Record>> {
        let user = try request.requireAuthenticated(User.self)
        return try user.patientSubscriptions
            .query(on: request)
            .join(\PatientAlert.patientId, to: \Patient.id)
            .alsoDecode(PatientAlert.self)
            .join(\Gateway.id, to: \PatientAlert.gatewayId)
            .alsoDecode(Gateway.self)
            .join(\Premise.id, to: \Gateway.premiseId)
            .alsoDecode(Premise.self)
            .join(\User.id, to: \PatientAlert.responderId)
            .alsoDecode(User.self)
            .join(\PatientTag.patientId, to: \Patient.id)
            .alsoDecode(PatientTag.self)
            .sort(\PatientAlert.creationDate, .descending)
            .all()
            .map({ joinedTables in
                try joinedTables.map {
                    try PatientAlert.Record(patientAlert: $0.0.0.0.0.1,
                                            patient: $0.0.0.0.0.0,
                                            responder: $0.0.1,
                                            gateway: $0.0.0.0.1,
                                            premise: $0.0.0.1,
                                            patientTag: $0.1)
                }.parse()
            })
    }
    
    class func getUserRespondedAlertRecords(_ request: Request) throws -> Future<ArrayResultWrapper<PatientAlert.Record>> {
        let user = try request.requireAuthenticated(User.self)
        return try user.patientSubscriptions
            .query(on: request)
            .join(\PatientAlert.patientId, to: \Patient.id)
            .filter(\PatientAlert.responderId == user.id)
            .alsoDecode(PatientAlert.self)
            .join(\Gateway.id, to: \PatientAlert.gatewayId)
            .alsoDecode(Gateway.self)
            .join(\Premise.id, to: \Gateway.premiseId)
            .alsoDecode(Premise.self)
            .join(\PatientTag.patientId, to: \Patient.id)
            .alsoDecode(PatientTag.self)
            .sort(\PatientAlert.creationDate, .descending)
            .all()
            .map({ joinedTables in
                try joinedTables.map {
                    try PatientAlert.Record(patientAlert: $0.0.0.0.1,
                                            patient: $0.0.0.0.0,
                                            gateway: $0.0.0.1,
                                            premise: $0.0.1,
                                            patientTag: $0.1)
                }.parse()
            })
    }
    
    class func getAlert(_ request: Request) throws -> Future<ResultWrapper<PatientAlert.Record>> {
        let user = try request.requireAuthenticated(User.self)
        let pateintAlertId = try request.parameters.next(Int.self)
        return try user.patientSubscriptions
            .query(on: request)
            .join(\PatientAlert.patientId, to: \Patient.id)
            .filter(\PatientAlert.id == pateintAlertId)
            .alsoDecode(PatientAlert.self)
            .join(\Gateway.id, to: \PatientAlert.gatewayId)
            .alsoDecode(Gateway.self)
            .join(\Premise.id, to: \Gateway.premiseId)
            .alsoDecode(Premise.self)
            .join(\PatientTag.patientId, to: \Patient.id)
            .alsoDecode(PatientTag.self)
            .first()
            .unwrap(or: Abort(.notFound))
            .map({ joinedTables in
                
                return try PatientAlert.Record(patientAlert: joinedTables.0.0.0.1,
                                               patient: joinedTables.0.0.0.0,
                                               gateway: joinedTables.0.0.1,
                                               premise: joinedTables.0.1,
                                               patientTag: joinedTables.1).parse()
            })
    }
    
    //MARK: - Web Services
    
    class func renderAlertRecords(_ request: Request) throws -> Future<View> {
        return try getAllCompletedAlertRecords(request)
            .flatMap { records in
                guard let result = records.result else {
                    throw Abort(.badRequest)
                }
                let context = ["records": result.map({ $0.mapToRenderable() })]
                return try request.view().render("alert-records", context)
        }
    }
    
    
}
