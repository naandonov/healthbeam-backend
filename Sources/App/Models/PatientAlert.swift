//
//  Alert.swift
//  App
//
//  Created by Nikolay Andonov on 13.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL

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
        
        struct Renderable: Content {
            var creationDate: String
            var respondDate: String?
            var status: String
            var notes: String?
            var gateway: Gateway.Public
            
            var patient: Patient.Public
            var responder: User.ExternalPublic?
        }
        
        var id: PatientAlert.ID
        var creationDate: Date
        var respondDate: Date?
        var status: String
        var notes: String?
        var gateway: Gateway.Public
        
        var patient: Patient.Public
        var patientTag: PatientTag.Public
        var responder: User.ExternalPublic?
        
        
        init(patientAlert: PatientAlert, patient: Patient, responder: User?=nil, gateway: Gateway, premise: Premise, patientTag: PatientTag) throws {
            id = try patientAlert.requireID()
            creationDate = patientAlert.creationDate
            if let respondDate = patientAlert.respondDate {
                self.respondDate = respondDate
            }
            status = patientAlert.status
            notes = patientAlert.notes
            self.patient = try patient.mapToPublic()
            if let responder = responder {
                self.responder = try responder.mapToExternalPublic()
            }
            self.patientTag = try patientTag.mapToPublic()
            self.gateway = try gateway.mapToPublic(forPremise: premise.mapToPublic())
        }
        
        func mapToRenderable() -> Renderable {
            return Renderable(creationDate: creationDate.extendedDateString(),
                              respondDate: respondDate?.extendedDateString(),
                              status: status,
                              notes: notes,
                              gateway: gateway,
                              patient: patient,
                              responder: responder)
        }
    }
    
    
    struct Encoded: Content {
        var value: String
    }
    
    var id: Int?
    var creationDate: Date
    var respondDate: Date?
    var status: String
    var notes: String?
    
    var patientId: Patient.ID?
    var responderId: User.ID?
    var gatewayId: Gateway.ID
    
    
    init(creationDate: Date, alertStatus: AlertStatus, gatewayId: Gateway.ID) {
        self.creationDate = creationDate
        self.status = alertStatus.rawValue
        self.gatewayId = gatewayId
    }
    
}

extension PatientAlert {

    var premise: Parent<PatientAlert, Gateway> {
        return parent(\.gatewayId)
    }
}

extension PatientAlert: Migration {
//    public static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            builder.reference(from: \.patientId, to: \Patient.id)
//            builder.reference(from: \.responderId, to: \User.id)
//        }
//    }
}

extension PatientAlert: Parameter {}
extension PatientAlert: PostgreSQLModel {}

extension PatientAlert {
    
    var notificationExtra: [String: String] {
        let idString: String
        if let id = id {
            idString = "\(id)"
        } else {
            idString = ""
        }
        return [
            "alertId": idString,
            "alertStatus": status
        ]
    }
}
