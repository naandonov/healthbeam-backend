//
//  WebAlertsController.swift
//  App
//
//  Created by Nikolay Andonov on 14.12.18.
//

import Foundation
import Vapor

class WebAlertsController: RouteCollection {
    
    func boot(router: Router) throws {
        
        router.get(WebConstants.AlertRecordsDirectory, use: AlertServices.renderAlertRecords)
    }
}
