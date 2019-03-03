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
        let healthRecordsModificationRouter = router.grouped("healthRecords").authorizedRouter()


        healthRecordsRouter.post(HealthRecord.Public.self, use: HealthRecordServices.createHealthRecord)
        healthRecordsRouter.get(use: HealthRecordServices.getHealthRecords)
        healthRecordsModificationRouter.put(HealthRecord.Public.self, at: "/", use: HealthRecordServices.updateHealthRecord)
        healthRecordsModificationRouter.delete(HealthRecord.ID.parameter, use: HealthRecordServices.deleteRecord)
    }
}
