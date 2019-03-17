//
//  WebPatientsController.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor

class WebPatientsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        router.get(WebConstants.PatientsListDirectory, use: PatientServices.renderPatientsList)
        router.get(WebConstants.PatientDescriptionDirectory, use: PatientServices.renderPatientDescription)
    }
}
