//
//  PatientsController.swift
//  App
//
//  Created by Nikolay Andonov on 3.12.18.
//

import Foundation
import Vapor


class PatientsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let tokenAuthenticationMiddleware = User.tokenAuthMiddleware()
        let authorizedRoute = router.grouped(tokenAuthenticationMiddleware)
        let patientsGroup = authorizedRoute.grouped(Constants.apiRoot, "patients")
        ServiceUtilities.generateOperations(router: patientsGroup, for: Patient.self, requireAuthorization: true, operationsSelector: .create, .get, .getAll, .update)
        
        patientsGroup.delete(Patient.parameter) {request -> Future<HTTPStatus> in
            _ = try request.requireAuthenticated(User.self)
           return try request.parameters.next(Patient.self)
                .flatMap({ patient -> Future<Void> in
                    try patient
                        .healthRecords
                        .query(on: request)
                        .delete()
                        .flatMap { _ in
                            patient.delete(on: request)
                    }
                }).transform(to: .ok)
        }
    }
}
