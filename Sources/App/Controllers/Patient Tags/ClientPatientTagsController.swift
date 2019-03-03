//
//  ClientPatientTagsController.swift
//  App
//
//  Created by Nikolay Andonov on 13.12.18.
//

import Foundation
import Vapor

class ClientPatientTagsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let patientTagRouter = router.grouped("patients", Patient.parameter).authorizedRouter()
        
        patientTagRouter.post(PatientTag.self, at: "assignTag", use: PatientTagServices.assignPatientTag)
        patientTagRouter.delete("unassignTag", use: PatientTagServices.unassignPatientTag)
        patientTagRouter.get("tag", use: PatientTagServices.getPatientTag)
    }

}
