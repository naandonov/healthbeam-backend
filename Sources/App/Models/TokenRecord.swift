//
//  Token.swift
//  App
//
//  Created by Nikolay Andonov on 10.12.18.
//

import Foundation
import FluentPostgreSQL
import Authentication

final class TokenRecord: Content {
    
    struct Public: Content {
        var accessToken: String
    }
    
    var id: Int?
    var token: String
    var userId: User.ID
    
    init(token: String, userId: User.ID) {
        self.token = token
        self.userId = userId
    }
    
    func mapToPublic() -> Public {
        return Public(accessToken: token)
    }
}

extension TokenRecord {
    var user: Parent<TokenRecord, User> {
        return parent(\.userId)
    }
}

extension TokenRecord: BearerAuthenticatable {
    static var tokenKey: WritableKeyPath<TokenRecord, String> { return \TokenRecord.token }
}

extension TokenRecord: Authentication.Token {
    typealias UserType = User
    typealias UserIDType = User.ID
    
    static var userIDKey: WritableKeyPath<TokenRecord, User.ID> {
        return \TokenRecord.userId
    }
}

extension TokenRecord: Migration {
//    public static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//        return Database.create(self, on: connection) { builder in
//            try addProperties(to: builder)
//            builder.reference(from: \.userId, to: \User.id)
//        }
//    }
}
extension TokenRecord: PostgreSQLModel {}
