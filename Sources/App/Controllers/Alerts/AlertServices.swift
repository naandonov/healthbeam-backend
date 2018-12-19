//
//  AlertServices.swift
//  App
//
//  Created by Nikolay Andonov on 14.12.18.
//

import Foundation
import Vapor
import FluentSQLite
import Crypto

class AlertServices {
    
    //MARK: - Client Services
    
    class func createAlert(_ request: Request, encoding: PatientAlert.Encoded) throws -> Future<PatientAlert> {
        
        guard let encryptedData = Data.init(fromHexEncodedString: encoding.value) else {
            throw Abort(.badRequest, reason:"Missing Ecnrypted Data")
        }
        
        let privateKey = try FileManager.shared.privateKeyContent()
        let decryptedData = try RSA.decrypt(encryptedData, padding: .pkcs1, key: .private(pem: privateKey))
        
        
        
        guard let decryptedString = String(data: decryptedData, encoding: .utf8),
            decryptedString.split(separator: "&").count == 3 else {
                throw Abort(.badRequest, reason:"Invalid request")
        }
        
        let decryptedValues = decryptedString.split(separator: "&")
        let requestTimeInterval = TimeInterval(decryptedValues[0])!
        let minor = Int(decryptedValues[1])!
        let major = Int(decryptedValues[2])!
        
        if (Date().timeIntervalSince1970 - requestTimeInterval) > 10 {
            throw Abort(.badRequest, reason:"Invalid request")
        }
        
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
                
                
                return patient.query(on: request).first().unwrap(or: notAssociatedTag).flatMap({ patient in
                    
                    return try PatientAlert.query(on: request)
                        .filter(\.status == AlertStatus.pending.rawValue)
                        .filter(\.patientId == patient.requireID())
                        .first().flatMap({ alert in
                            
                            if let _ = alert {
                                throw Abort(.notFound, reason: "There is an existing pending alert for the specified patient.")
                            }
                            
                            let newAlert = PatientAlert(creationDate: Date(), alertStatus: .pending)
                            try newAlert.patientId = patient.requireID()
                            
                            //                    TODO: Dispatch Push Notificaitons
                            //                    patient.observers.query(on: request).all().flatMap({ observers in
                            //
                            //                    })
                            
                            return newAlert.save(on: request)
                        })
                })
            })
    }
    
    class func respondToAlert(_ request: Request, subscription: Patient.Subscribtion) throws -> Future<HTTPStatus> {
        let user = try request.requireAuthenticated(User.self)
        let notFound = Abort(.notFound, reason: "No alert exists for the subscribed patients")
        return try user.patientSubscriptions
            .query(on: request)
            .filter(\.id == subscription.patientId)
            .first()
            .unwrap(or: notFound).flatMap({ (patient: Patient) in
                return PatientAlert
                    .query(on: request)
                    .join(\Patient.id, to: \PatientAlert.patientId)
                    .filter(\PatientAlert.status == AlertStatus.pending.rawValue)
                    .first()
                    .flatMap({ (alert: PatientAlert?) -> Future<PatientAlert> in
                        guard let alert = alert else {
                            throw notFound
                        }
                        alert.respondDate = Date()
                        alert.status = AlertStatus.responded.rawValue
                        alert.responderId = try user.requireID()
                        return alert.update(on: request)
                    })
                    .transform(to: HTTPStatus.ok)
            })
    }
    
    
    class func getPendingAlerts(_ request: Request) throws -> Future<[PatientAlert.Record]> {
        let user = try request.requireAuthenticated(User.self)
        return try user.patientSubscriptions
            .query(on: request)
            .join(\PatientAlert.patientId, to: \Patient.id)
            .alsoDecode(PatientAlert.self)
            .filter(\PatientAlert.status == AlertStatus.pending.rawValue)
            .all()
            .map({ joinedTables in
                try joinedTables.map {
                    try PatientAlert.Record(patientAlert: $0.1, patient: $0.0)
                }
            })
    }
    
    class func getAlertRecords(_ request: Request) throws -> Future<[PatientAlert.Record]> {
        _ = try request.requireAuthenticated(User.self)
        return PatientAlert
            .query(on: request)
            .join(\Patient.id, to: \PatientAlert.patientId)
            .alsoDecode(Patient.self)
            .join(\User.id, to: \PatientAlert.responderId)
            .alsoDecode(User.self)
            .all()
            .map({ joinedTables in
                try joinedTables.map {
                    try PatientAlert.Record(patientAlert: $0.0.0, patient: $0.0.1, responder: $0.1)
                }
            })
    }
    
    //MARK: - Web Services
    
    class func renderAlertRecords(_ request: Request) throws -> Future<View> {
        return try getAlertRecords(request)
            .flatMap { records in
                let context = ["records": records]
                return try request.view().render("alert-records", context)
        }
    }
    
    
}
