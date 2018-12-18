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
    
    class func createAlert(_ request: Request, encodedValue: PatientAlert.Encoded) throws -> Future<PatientAlert> {
        
        let directory = DirectoryConfig.detect()
        let configDir = "Resources"
        
        let publicKeyData = try Data(contentsOf: URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent(configDir, isDirectory: true)
            .appendingPathComponent("publicKey.key", isDirectory: false))
        
        let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent(configDir, isDirectory: true)
            .appendingPathComponent("privateKey.key", isDirectory: false))
        
        let encryptedData = try RSA.encrypt("1&0", key: .public(pem: publicKeyData))
        
        let data = encodedValue.value.data(using: .utf8)
        
        let decryptedData = try RSA.decrypt(data!, key: .private(pem: privateKeyData))

        
        
        
        _ = try request.requireAuthenticated(User.self)
        let notAssociatedTag = Abort(.notFound, reason: "No patient is associated with this tag")
        return PatientTag.query(on: request)
//            .filter(\PatientTag.minor, .equal, patientTag.minor)
//            .filter(\PatientTag.major, .equal, patientTag.major)
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
    
    
    class func getPendingAlerts(_ request: Request) throws -> Future<[Patient]> {
        let user = try request.requireAuthenticated(User.self)
        return try user.patientSubscriptions
            .query(on: request)
            .join(\PatientAlert.patientId, to: \Patient.id)
            .filter(\PatientAlert.status == AlertStatus.pending.rawValue)
            .all()
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
                var records: [PatientAlert.Record] = []
                for row in joinedTables {
                    try records.append(PatientAlert.Record(patientAlert: row.0.0, patient: row.0.1, responder: row.1))
                }
                return records
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
