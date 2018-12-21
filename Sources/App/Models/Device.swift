//
//  UserDevice.swift
//  App
//
//  Created by Nikolay Andonov on 21.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL


final class Device: Content {
    
    struct Request: Content {
        var deviceToken: String
        
        func model() -> Device {
            return Device(deviceToken: deviceToken)
        }
    }
    
    var id: Int?
    var deviceToken: String
    var userId: User.ID?
    
    init(deviceToken: String) {
        self.deviceToken = deviceToken
    }
}

extension Device: Parameter {}
extension Device: PostgreSQLModel {}
extension Device: Migration {}
