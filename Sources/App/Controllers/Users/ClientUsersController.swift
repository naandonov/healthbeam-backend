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
//        userRouter.get("subscriptions", use: UserServices.getPatientSubscriptions)
        let subscriptionsRouter = userRouter.grouped("subscriptions")
        ServiceUtilities.generateBatchOperation(router: subscriptionsRouter, type: Patient.self) { user in
            guard let userId = user.id else {
                return []
            }
            return [
                .innerJoin(statements: [(table: "Patient_User", connectionKey: "Patient.id", tableKey: "patientId"),
                                        (table: "User", connectionKey: "Patient_User.userId", tableKey: "User.id")]),
                .searchQuery(keyName: "Patient.fullName"),
                .filter(keyValuePairs:["User.id" : "\(userId)"]),
                .sort(keyName: "Patient.fullName", isAscending: true)
            ]
        }
        userRouter.post("assignToken", use: UserServices.saveDeviceToken)

    }
}
