//
//  AuthenticationServices.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor
import FluentSQLite
import Crypto
import Random

class AuthenticationServices {
    
    //MARK: - Client Services
    
    class func register(_ request: Request) throws -> Future<User.Public> {
        return try request.content.decode(User.self).flatMap { user in
            return User.query(on: request).filter(\.email == user.email).first().flatMap { existingUser -> Future<User.Public> in
                if let _ = existingUser {
                    throw Abort(.badRequest, reason: "Registration for '\(user.email)' already exists")
                }
                user.password = try BCryptDigest().hash(user.password)
                return user.save(on: request).map { newUser in
                    return try newUser.mapToPublic()
                }
            }
        }
    }
    
    class func login(_ request: Request) throws -> Future<TokenRecord> {
        return try request.content.decode(User.Login.self).flatMap { userLogin in
            return User.query(on: request)
                .filter(\.email == userLogin.email)
                .first()
                .flatMap { fetchedUser in
                    guard let existingUser = fetchedUser else {
                        throw Abort(.notFound, reason: "Invalid credentials")
                    }
                    let hasher = try request.make(BCryptDigest.self)
                    if try hasher.verify(userLogin.password, created: existingUser.password) {
                        return try TokenRecord
                            .query(on: request)
                            .filter(\TokenRecord.userId, .equal, existingUser.requireID())
                            .delete()
                            .flatMap { _ in
                                let tokenString = try URandom().generateData(count: 32).base64EncodedString()
                                let token = try TokenRecord(token: tokenString, userId: existingUser.requireID())
                                return token.save(on: request)
                        }
                    } else {
                        throw Abort(.notFound, reason: "Invalid credentials")
                    }
            }
        }
    }
    
    class func logout(_ request: Request) throws -> Future<HTTPResponse> {
        let user = try request.requireAuthenticated(User.self)
        return try TokenRecord
            .query(on: request)
            .filter(\TokenRecord.userId, .equal, user.requireID())
            .delete()
            .transform(to: HTTPResponse(status: .ok))
    }
    
    
    //MARK: - Web Services
    
    class func webRegister(_ request: Request) throws -> Future<Response> {
        
        return try register(request).map(to: Response.self, { _ -> Response in
            request.redirect(to: WebConstants.HomeDirectory)
        }).mapIfError { error in
            request.redirect(to: WebConstants.CreateAccountDirectory)
        }
    }
    
    class func webLogin(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(User.Login.self).flatMap { user in
            return User.authenticate(
                username: user.email,
                password: user.password,
                using: BCryptDigest(),
                on: req
                ).map { user in
                    guard let user = user else {
                        return req.redirect(to: WebConstants.UnauthorizedDirectory)
                    }
                    try req.authenticateSession(user)
                    return req.redirect(to: WebConstants.HomeDirectory)
            }
        }
    }
    
    
    
}
