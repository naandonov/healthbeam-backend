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
        ServiceUtilities.generateBatchOperation(router: patientsRouter, type: Patient.self) { user in
            return [.searchQuery(keyName: "fullName"), .filter(keyValuePairs:["premiseId" : "\(user.premiseId)"]), .sort(keyName: "fullName", isAscending: true)]
        }
        
        patientsRouter.delete(Patient.parameter, use: PatientServices.deletePatient)
        patientsRouter.get(Patient.parameter, use: PatientServices.getPatient)
        patientsRouter.get(Patient.parameter, "attributes", use: PatientServices.getPatientAttributes)
//        patientsRouter.get(use: PatientServices.getAllPatients)
        patientsRouter.post(Patient.Public.self, at: "/", use: PatientServices.cretePatient)
        patientsRouter.put(Patient.Public.self, at: "/", use: PatientServices.updatePatient)
//      patientsRouter.get("query", use: PatientServices.searchPatients)
    }
}
