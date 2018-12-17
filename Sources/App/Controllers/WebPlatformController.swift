//
//  WebPlatformController.swift
//  App
//
//  Created by Nikolay Andonov on 9.12.18.
//

import Foundation
import Vapor
import Crypto
import FluentSQLite
import Authentication

class WebPlatformController: RouteCollection {
    func boot(router: Router) throws {
        
        let authSessionRouter = router.grouped(User.authSessionsMiddleware())
//        authSessionRouter.post("weblogin", use: login)
        
        authSessionRouter.get("patients-list"){ request -> Future<View> in
            return try request.view().render("patients-list")
        }
        
        authSessionRouter.get("/"){ request -> Future<View> in
            if try request.isAuthenticated(User.self) {
                return try request.view().render("home")
            }
            return try request.view().render("login")
        }
        
        let protectedRouter = authSessionRouter.grouped(RedirectMiddleware<User>(path: "/"))
        protectedRouter.get("home") { request -> Future<View> in
            return try request.view().render("home")
        }
        
        protectedRouter.get("create-account"){ request -> Future<View> in
            return try request.view().render("create-account")
        }
        
        
    }
}

