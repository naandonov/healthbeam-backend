//
//  GatewayServices.swift
//  App
//
//  Created by Nikolay Andonov on 9.02.19.
//

import Foundation
import Vapor
import FluentPostgreSQL

class GatewayServices {
    
    class func create(_ request: Request) throws -> Future<ResultWrapper<Gateway.Public>> {
        let user = try request.requireAuthenticated(User.self)
        return user.premise.query(on: request)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ premise  in
                
                return try request.content.decode(Gateway.Registration.self).flatMap({ (input: Gateway.Registration) -> Future<ResultWrapper<Gateway.Public>>  in
                    let gateway: Gateway = try Gateway(id: nil, codeIdentifier: input.codeIdentifier, name: input.name, premiseId: premise.requireID())
                    
                    
                   return Gateway.query(on: request)
                        .join(\Premise.id, to: \Gateway.premiseId)
                        .filter(\Gateway.codeIdentifier, .equal, input.codeIdentifier)
                        .first().flatMap({ existingGateway -> Future<ResultWrapper<Gateway.Public>> in
                            guard existingGateway == nil else {
                                throw Abort(.badRequest, reason: "Gateway with this code identifier already exists")
                            }
                            
                            return gateway.save(on: request).map({ savedGateway in
                                return try savedGateway.mapToPublic(forPremise: premise.mapToPublic()).parse()
                        })
                    })
                })
            })
    }
    
    //Web Services
    
    class func renderCreateGateway(_ request: Request) throws -> Future<View> {
        let _ = try request.requireAuthenticated(User.self)
        return try request.view().render("create-gateway")
    }
    
    class func webCreate(_ request: Request) throws -> Future<Response> {
        _ = try request.requireAuthenticated(User.self)
        
        return try create(request).map(to: Response.self, { _ -> Response in
            request.redirect(to: WebConstants.HomeDirectory)
        }).mapIfError { error in
            request.redirect(to: WebConstants.CreateAccountDirectory)
        }
    }
    
}


