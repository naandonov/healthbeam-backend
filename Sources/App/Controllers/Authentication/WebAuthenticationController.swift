//
//  WebAuthenticationController.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor
import Authentication


class WebAuthenticationController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let authSessionRouter = router.authSessionRouter()
        let protectedRouter = authSessionRouter.protectedRouter()
        
        protectedRouter.get(WebConstants.CreateAccountDirectory, use: AuthenticationServices.renderRegistration)
        
        //Triggers
        protectedRouter.post("webregister", use: AuthenticationServices.webRegister)
        authSessionRouter.post("weblogin", use: AuthenticationServices.webLogin)
        
        
    }
}
