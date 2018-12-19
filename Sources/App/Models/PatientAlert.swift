//
//  Alert.swift
//  App
//
//  Created by Nikolay Andonov on 13.12.18.
//

import Foundation
import Vapor
import FluentSQLite

enum AlertStatus: String {
    case pending = "pending"
    case responded = "responded"
    case unknowned = "unknowned"
    
    
    static func statusFor(_ stringValue: String) -> AlertStatus {
        if stringValue == AlertStatus.pending.rawValue {
            return .pending
        }
        else if stringValue == AlertStatus.responded.rawValue {
            return .responded
        }
        else {
            return .unknowned
        }
    }
}

final class PatientAlert: Content {
    
    struct Record: Content {
        
        var id: PatientAlert.ID
        var creationDate: String
        var respondDate: String?
        var status: String
        
        var patient: Patient.Public
        var responder: User.ExternalPublic?
        
        
        init(patientAlert: PatientAlert, patient: Patient, responder: User?=nil) throws {
            self.id = try patientAlert.requireID()
            self.creationDate = patientAlert.creationDate.extendedDateString()
            if let respondDate = patientAlert.respondDate {
                self.respondDate = respondDate.extendedDateString()
            }
            self.status = patientAlert.status
            
            self.patient = try patient.mapToPublic()
            if let responder = responder {
                self.responder = try responder.mapToExternalPublic()
            }
        }
    }
    
    
    struct Encoded: Content {
        var value: String
    }
    
    var id: Int?
    var creationDate: Date
    var respondDate: Date?
    var status: String
    
    var patientId: Patient.ID?
    var responderId: User.ID?
    
    init(creationDate: Date, alertStatus: AlertStatus) {
        self.creationDate = creationDate
        self.status = alertStatus.rawValue
    }
    
}

extension PatientAlert: Migration {
    public static func prepare(on connection: SQLiteConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.patientId, to: \Patient.id)
            builder.reference(from: \.responderId, to: \User.id)
        }
    }
}

extension PatientAlert: Parameter {}
extension PatientAlert: SQLiteModel {}

