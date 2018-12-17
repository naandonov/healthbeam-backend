//
//  AuthenticationController.swift
//  App
//
//  Created by Nikolay Andonov on 2.12.18.
//

import Foundation
import Vapor
import FluentSQLite
import Crypto
import Random

class AuthenticationController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let authenticationRoot = router.grouped(Constants.apiRoot)
        let tokenAuthenticationMiddleware = User.tokenAuthMiddleware()
        let authorizedRoute = authenticationRoot.grouped(tokenAuthenticationMiddleware)
        authenticationRoot.post("register", use: register)
        authenticationRoot.post("login", use: login)
        authorizedRoute.get("logout", use: logout)
        
        //        authenticationRoot.post(User.self, at: "registration", String.parameter, use: createAuthenticationRecord)
        //        authenticationRoot.delete("registration", String.parameter, use: deleteAuthenticationRecord)
        //        authenticationRoot.get("registrations", use: fetchAuthenticationRecords)
        //        authenticationRoot.get("login", String.parameter, use: passcodeLogin)
        
    }
    
    func register(_ request: Request) throws -> Future<User.Public> {
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
    
    func login(_ request: Request) throws -> Future<TokenRecord> {
        return try request.content.decode(User.Login.self).flatMap { userLogin in
            return User.query(on: request).filter(\.email == userLogin.email).first().flatMap { fetchedUser in
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
    
    func logout(_ request: Request) throws -> Future<HTTPResponse> {
        let user = try request.requireAuthenticated(User.self)
        return try TokenRecord
            .query(on: request)
            .filter(\TokenRecord.userId, .equal, user.requireID())
            .delete()
            .transform(to: HTTPResponse(status: .ok))
    }
    
    
    //    func createAuthenticationRecord(request: Request, user: User) throws -> Future<AuthenticationRecord> {
    //        return Future.flatMap(on: request, { () -> Future<AuthenticationRecord> in
    //            let passcode = try request.parameters.next(String.self)
    //            let existingRecordsCount = AuthenticationRecord.query(on: request).filter(\.passcode == passcode).count()
    //            return existingRecordsCount.flatMap{ count in
    //                guard count == 0 else {
    //                    throw Abort(.conflict, reason: "Registration for '\(passcode)' already exists")
    //                }
    //                let record = AuthenticationRecord(passcode: passcode, user: user)
    //                return record.save(on: request)
    //            }
    //        })
    //    }
    //
    //
    //
    //
    //    func deleteAuthenticationRecord(request: Request) throws -> Future<AuthenticationRecord> {
    //        let passcode = try request.parameters.next(String.self)
    //        let recordForDeletition = AuthenticationRecord.query(on: request).filter(\.passcode == passcode).first()
    //        return recordForDeletition.map{ record -> AuthenticationRecord in
    //            guard let record = record else {
    //                throw Abort(.notFound, reason: "Registration Record for '\(passcode)' not found")
    //            }
    //            _ = record.delete(on: request)
    //            return record
    //        }
    //    }
    //
    //    func fetchAuthenticationRecords(request: Request) -> Future<[AuthenticationRecord]> {
    //        return AuthenticationRecord.query(on: request).all()
    //    }
    //
    //    func passcodeLogin(request: Request) throws -> Future<AuthenticationRecord> {
    //        let passcode = try request.parameters.next(String.self)
    //        let loginRequest = AuthenticationRecord.query(on: request).filter(\.passcode == passcode).first()
    //        return loginRequest.flatMap { record in
    //            guard let record = record else {
    //               throw Abort(.forbidden, reason: "Invalid Passcode")
    //            }
    //            let accessToken = UUID().uuidString
    //            record.accessToken = accessToken
    //            return record.save(on: request)
    //        }
    //    }
}
