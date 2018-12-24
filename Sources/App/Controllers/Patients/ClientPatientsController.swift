//
//  ClientPatientsController.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor

class ClientPatientsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let patientsRouter = router.grouped("patients").authorizedRouter()
//        ServiceUtilities.generateOperations(router: patientsRouter, for: Patient.self, requireAuthorization: true, operationsSelector: .getAll)
        ServiceUtilities.generateBatchOperation(router: patientsRouter, type: Patient.self, queryConfigurations: [.filter(keyName: "fullName")])
        
        patientsRouter.delete(Patient.parameter, use: PatientServices.deletePatient)
//        patientsRouter.get(Patient.parameter, use: PatientServices.getPatient)
//        patientsRouter.get(use: PatientServices.getAllPatients)
        patientsRouter.post(Patient.Public.self, at: "/", use: PatientServices.cretePatient)
        patientsRouter.put(Patient.Public.self, at: "/", use: PatientServices.updatePatient)
//      patientsRouter.get("query", use: PatientServices.searchPatients)
    }
}
