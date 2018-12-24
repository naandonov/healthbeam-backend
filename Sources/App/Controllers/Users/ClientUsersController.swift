//
//  ClientUsersController.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor

class ClientUsersController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let userRouter = router.grouped("user").authorizedRouter()
        userRouter.get("/", use: UserServices.getUserInfo)
        userRouter.post("subscribe", use: UserServices.subscribeToPatient)
        userRouter.post("unsubscribe", use: UserServices.unsubscribeToPatient)
        userRouter.get("subscriptions", use: UserServices.getPatientSubscriptions)
        userRouter.post("assignToken", use: UserServices.saveDeviceToken)

    }
}
