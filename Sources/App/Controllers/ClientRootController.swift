//
//  RootClientController.swift
//  App
//
//  Created by Nikolay Andonov on 12.12.18.
//

import Foundation
import Vapor


class ClientRootController: RouteCollection {
    
    func boot(router: Router) throws {
        try registerClientControllersFor(router)
    }
    
    func registerClientControllersFor(_ router: Router) throws {

        let rootRouter = router.grouped(Constants.apiRoot)
        
        let clientAuthenticationController = ClientAuthenticationController()
        try rootRouter.register(collection: clientAuthenticationController)
        
        let clientUsersController = ClientUsersController()
        try rootRouter.register(collection: clientUsersController)
        
        let clientPatientsController = ClientPatientsController()
        try rootRouter.register(collection: clientPatientsController)
        
        let clientHealthRecordsController = ClientHealthRecordsController()
        try rootRouter.register(collection: clientHealthRecordsController)
        
        let clientPatientTagsController = ClientPatientTagsController()
        try rootRouter.register(collection: clientPatientTagsController)
        
        let clientAlertsController = ClientAlertsController()
        try rootRouter.register(collection: clientAlertsController)
    }
}
