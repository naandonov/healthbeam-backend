//
//  WebGatewayController.swift
//  App
//
//  Created by Nikolay Andonov on 9.02.19.
//

import Foundation
import Vapor


class WebGatewayController: RouteCollection {
    func boot(router: Router) throws {
        
        let authSessionRouter = router.authSessionRouter()
        let protectedRouter = authSessionRouter.protectedRouter()
        
        protectedRouter.get(WebConstants.CreateGatewayDirectory, use: GatewayServices.renderCreateGateway)
        
        //Triggers
        protectedRouter.post("creategateway", use: GatewayServices.webCreate)
        
    }
    
    
    
}
