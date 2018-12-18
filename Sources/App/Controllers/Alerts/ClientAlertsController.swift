//
//  ClientAlertsController.swift
//  App
//
//  Created by Nikolay Andonov on 14.12.18.
//

import Foundation
import Vapor

class ClientAlertsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let alertRouter = router.grouped("alerts").authorizedRouter()
        alertRouter.post(PatientAlert.Encoded.self, at: "generate", use: AlertServices.createAlert)
        alertRouter.post(Patient.Subscribtion.self, at: "respond", use: AlertServices.respondToAlert)
        alertRouter.get("pending", use: AlertServices.getPendingAlerts)
        alertRouter.get("records", use: AlertServices.getAlertRecords)
        
    }
    
}
