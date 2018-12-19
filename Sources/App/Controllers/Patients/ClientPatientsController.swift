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
        ServiceUtilities.generateOperations(router: patientsRouter, for: Patient.self, requireAuthorization: true, operationsSelector: .create, .get, .getAll, .update)
        patientsRouter.delete(Patient.parameter, use: PatientServices.deletePatient)
        patientsRouter.get(use: PatientServices.searchPatients)
    }
}
