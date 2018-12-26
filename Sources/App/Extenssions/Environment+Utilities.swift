//
//  Environment+Utilities.swift
//  App
//
//  Created by Nikolay Andonov on 26.12.18.
//

import Vapor

extension Environment {
    
    static var DATABASE_URL: String? {
        return Environment.get("DATABASE_URL")
    }
    
    static var IS_PRODUCTION_ENVIRONMENT: Bool {
        return Environment.get("ENVIRONMENT") == "Production"
    }
    
    static var PUSH_CERTIFICATE_PWD: String {
        if IS_PRODUCTION_ENVIRONMENT {
            return Environment.get("PUSH_CERTIFICATE_PWD") ?? "password"
        }
        else {
            return Environment.get("PUSH_DEV_CERTIFICATE_PWD") ?? "password"
        }
    }
    
    static var BUNDLE_IDENTIFIER: String {
        return Environment.get("BUNDLE_IDENTIFIER") ?? ""
    }
    
}
