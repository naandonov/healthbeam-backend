//
//  GeneralWebController.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor

enum WebConstants {
    static let HomeDirectory = "home"
    static let CreateAccountDirectory = "create-account"
    static let CreateGatewayDirectory = "create-gateway"
    static let AlertRecordsDirectory = "alert-records"
    static let PatientsListDirectory = "patients-list"
    static let PatientDescriptionDirectory = "/patient"
    static let TermsAndConditionsDirectory = "terms-and-conditions"
    static let PrivacyPolicyDirectory = "privacy-policy"
    static let LoginDirectory = "/"
    static let UnauthorizedDirectory = "/"
    static let RootDirectory = "/"
}


class WebRootController: RouteCollection {

    func boot(router: Router) throws {
        try registerWebControllersFor(router)
        
        let authSessionRouter = router.authSessionRouter()
        let protectedRouter = authSessionRouter.protectedRouter()
        
        authSessionRouter.get(WebConstants.RootDirectory){ request -> Future<View> in
            if try request.isAuthenticated(User.self) {
                return try request.view().render("home")
            }
            return try request.view().render("login")
        }
        
        protectedRouter.get(WebConstants.HomeDirectory) { request -> Future<View> in
            return try request.view().render("home")
        }
    }
    
    func registerWebControllersFor(_ router: Router) throws {
        let protectedRouter = router.authSessionRouter().protectedRouter()
        
        let webAuthenticationController = WebAuthenticationController()
        try router.register(collection: webAuthenticationController)
        
        let webAlertsController = WebAlertsController()
        try protectedRouter.register(collection: webAlertsController)
        
        let webPatientsController = WebPatientsController()
        try protectedRouter.register(collection: webPatientsController)
        
        let webGatewayController = WebGatewayController()
        try protectedRouter.register(collection: webGatewayController)
        
        let webGeneralController = WebGeneralController()
        try router.authSessionRouter().register(collection: webGeneralController)
    }
}
