//
//  WebGeneralController.swift
//  App
//
//  Created by Nikolay Andonov on 13.02.19.
//

import Foundation
import Vapor

class WebGeneralController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let authSessionRouter = router.authSessionRouter()
        
        authSessionRouter.get(WebConstants.TermsAndConditionsDirectory){ request -> Future<View> in
            return try request.view().render("terms-and-conditions")
        }
        
        authSessionRouter.get(WebConstants.PrivacyPolicyDirectory){ request -> Future<View> in
            return try request.view().render("privacy-policy")
        }
        
    }
}
