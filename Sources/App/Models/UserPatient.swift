//
//  UserPatientPivot.swift
//  App
//
//  Created by Nikolay Andonov on 11.12.18.
//

import Foundation
import Vapor
import FluentSQLite


final class UserPatient: SQLitePivot, ModifiablePivot {
    
    typealias Left = User
    typealias Right = Patient
    
    static var leftIDKey: LeftIDKey = \.userId
    static var rightIDKey: RightIDKey = \.patientId
    
    var id: Int?
    var userId: User.ID
    var patientId: Patient.ID
    
    init(_ user: User, _ patient: Patient) throws {
        userId = try user.requireID()
        patientId = try patient.requireID()
    }
}

extension UserPatient: Migration {}
