//
//  Operator.swift
//  App
//
//  Created by Nikolay Andonov on 2.12.18.
//

import Foundation
import Vapor
import FluentSQLite
import Authentication

final class User: Content {
    
    struct ExternalPublic: Content {
        var id: Int
        var fullName: String
        var designation: String
    }
    
    struct Public: Content {
        var id: Int
        var fullName: String
        var designation: String
        var email: String
        var discoveryRegions: [String]
        var accountType: String?
    }
    
    struct Login: Content {
        var email: String
        var password: String
    }
    
    var id: Int?
    var fullName: String
    var designation: String
    var email: String
    var password: String
    var discoveryRegions: [String]
    var accountType: String?
    
    init(fullName: String, designation: String, email: String, password: String, discoveryRegions: [String] = []) {
        self.fullName = fullName
        self.designation = designation
        self.email = email
        self.password = password
        self.discoveryRegions = discoveryRegions
        accountType = "standard"
    }
    
    func mapToPublic() throws -> User.Public {
        return try User.Public(id: self.requireID(),
                               fullName: fullName,
                               designation: designation,
                               email: email,
                               discoveryRegions: discoveryRegions,
                               accountType: accountType)
    }
    
    func mapToExternalPublic() throws -> User.ExternalPublic {
        return try User.ExternalPublic(id: self.requireID(),
                                       fullName: fullName,
                                       designation: designation)
    }
    
}

extension User {
    var patientSubscriptions: Siblings<User, Patient, UserPatient> {
        return siblings()
    }
}

extension User: TokenAuthenticatable {
    typealias TokenType = TokenRecord
}

extension User: PasswordAuthenticatable {
    static var usernameKey: WritableKeyPath<User, String> {
        return \User.email
    }
    static var passwordKey: WritableKeyPath<User, String> {
        return \User.password
    }
}
extension User: SessionAuthenticatable {}

extension User: Parameter {}
extension User: SQLiteModel {}
extension User: Migration {}
