//
//  AuthenticationServices.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Crypto
import Random

class AuthenticationServices {
    
    //MARK: - Client Services
    
    class func register(_ request: Request) throws -> Future<User.Public> {
        let user = try request.requireAuthenticated(User.self)
        return try request.content.decode(User.Registration.self).flatMap { userInput in
            return User.query(on: request).filter(\.email == userInput.email).first().flatMap { existingUser -> Future<User.Public> in
                if let existingUser = existingUser {
                    throw Abort(.badRequest, reason: "Registration for '\(existingUser.email)' already exists")
                }
                let privateUser = User(fullName: userInput.fullName,
                                       designation: userInput.designation,
                                       email: userInput.email,
                                       password: try BCryptDigest().hash(userInput.password),
                                       discoveryRegions: userInput.discoveryRegions,
                                       premiseId: user.premiseId,
                                       accountType: "standard")
                
                return privateUser.save(on: request).map { newUser in
                    return try newUser.mapToPublic()
                }
            }
        }
    }
    
    class func login(_ request: Request) throws -> Future<ResultWrapper<TokenRecord.Public>> {
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
                        return try logoutHelper(request, user: existingUser)
                            .flatMap { _ in
                                let tokenString = try URandom().generateData(count: 32).base64EncodedString()
                                let token = try TokenRecord(token: tokenString, userId: existingUser.requireID())
                                return token.save(on: request).map { token in
                                    token.mapToPublic().parse()
                                }
                        }
                    } else {
                        throw Abort(.notFound, reason: "Invalid credentials")
                    }
            }
        }
    }
    
    class func logout(_ request: Request) throws -> Future<FormattedResultWrapper> {
        let user = try request.requireAuthenticated(User.self)
        return try logoutHelper(request, user: user).map{ response  in
            if response.status == .ok {
                return FormattedResultWrapper(result: .success)
            }
            return FormattedResultWrapper(result: .faliure)
        }
    }
    
    private class func logoutHelper(_ request: Request, user: User) throws -> Future<HTTPResponse> {
        return try TokenRecord
            .query(on: request)
            .filter(\TokenRecord.userId, .equal, user.requireID())
            .delete()
            .flatMap{ _ in
                try user.userDevice.query(on: request)
                    .delete()
                    .transform(to: HTTPResponse(status: .ok))
        }
    }
    
    
    //MARK: - Web Services
    
    class func renderRegistration(_ request: Request) throws -> Future<View> {
        let user = try request.requireAuthenticated(User.self)
        
        return user
            .premise
            .query(on: request)
            .first()
            .unwrap(or: Abort(.badRequest, reason: "Missing required data"))
            .flatMap { premise in
                let context = try ["hospital": premise.mapToPublic()]
                return try request.view().render("create-account", context)
        }
    }
    
    class func webRegister(_ request: Request) throws -> Future<Response> {
        _ = try request.requireAuthenticated(User.self)
        
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
