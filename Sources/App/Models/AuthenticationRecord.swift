//
//  AuthenticationRecord.swift
//  App
//
//  Created by Nikolay Andonov on 2.12.18.
//

import Foundation
import Vapor
import FluentSQLite

final class AuthenticationRecord: Content {
    
    struct Context: Content {
        
        var fullName: String
        var designation: String
        var passcode: String
        var proximityUUIDs: String
        
        init(fullName: String, lastName: String, designation: String, passcode: String, proximityUUIDs: String) {
            self.fullName = fullName
            self.designation = designation
            self.proximityUUIDs = proximityUUIDs
            self.passcode = passcode
        }
    }
    
    var id: Int?
    
    var passcode: String
    var user: User
    var accessToken: String?
    
    init(passcode: String, user: User, accessToken: String? = nil) {
        self.passcode = passcode
        self.user = user
        self.accessToken = accessToken
    }
    
}

extension AuthenticationRecord: Parameter {}
extension AuthenticationRecord: SQLiteModel {}
extension AuthenticationRecord: Migration {}
