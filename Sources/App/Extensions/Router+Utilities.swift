//
//  Router+Utilities.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor
import Authentication

extension Router {
    
    func authorizedRouter() -> Router {
        let tokenAuthenticationMiddleware = User.tokenAuthMiddleware()
        return self.grouped(tokenAuthenticationMiddleware)
    }
    
    func authSessionRouter() -> Router {
        return self.grouped(User.authSessionsMiddleware())
    }
    
    func protectedRouter() -> Router {
        return self.grouped(RedirectMiddleware<User>(path: WebConstants.UnauthorizedDirectory))
    }
}
