//
//  ClientAuthenticationController.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor

class ClientAuthenticationController: RouteCollection {
    
    func boot(router: Router) throws {
        
        router.post("login", use: AuthenticationServices.login)
        router.authorizedRouter().post("register", use: AuthenticationServices.register)
        router.authorizedRouter().get("logout", use: AuthenticationServices.logout)
    }
}
