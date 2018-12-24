//
//  ClientHealthRecordsController.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor

class ClientHealthRecordsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let healthRecordsRouter = router.grouped("patients", Patient.parameter, "healthRecords").authorizedRouter()

        healthRecordsRouter.post(HealthRecord.Request.self, use: HealthRecordServices.createHealthRecord)
        healthRecordsRouter.get(use: HealthRecordServices.getHealthRecords)
        healthRecordsRouter.put(HealthRecord.Request.self, at: "/", use: HealthRecordServices.updateHealthRecord)
        healthRecordsRouter.delete(HealthRecord.ID.parameter, use: HealthRecordServices.deleteRecord)
    }
}