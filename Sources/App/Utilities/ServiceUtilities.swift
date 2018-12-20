//
//  ServiceUtilities.swift
//  App
//
//  Created by Nikolay Andonov on 5.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL

typealias CRUDModelProvider = Content & Parameter & PostgreSQLModel

enum CRUDOperationSelector {
    case create
    case get
    case getAll
    case update
    case delete
}

class ServiceUtilities {
    
    
    class func generateAllOperations<T: CRUDModelProvider>(router: Router, for type: T.Type, requireAuthorization: Bool = false) {
        generateOperations(router: router, for: type, operationsSelector: .create, .get, .getAll, .update, .delete)
    }
    
    class func generateOperations<T: CRUDModelProvider>(router: Router, for type: T.Type, requireAuthorization: Bool = false, operationsSelector: CRUDOperationSelector...) {
        
        if operationsSelector.contains(.create) {
            router.post(T.self, at:"/") {(request, content: T) -> Future<T> in
                if requireAuthorization {
                    _ = try request.requireAuthenticated(User.self)
                }
                return content.save(on: request)
            }
        }
        if operationsSelector.contains(.getAll) {
            router.get() {request -> Future<[T]> in
                if requireAuthorization {
                    _ = try request.requireAuthenticated(User.self)
                }
                return T.query(on: request).all()
            }
        }
        if operationsSelector.contains(.get) {
            router.get(T.parameter) {request -> Future<T> in
                if requireAuthorization {
                    _ = try request.requireAuthenticated(User.self)
                }
                return try request
                    .parameters
                    .next(T.self) as! Future<T>
            }
        }
        if operationsSelector.contains(.delete) {
            router.delete(T.parameter) {request -> Future<HTTPStatus> in
                if requireAuthorization {
                    _ = try request.requireAuthenticated(User.self)
                }
                return try (request
                    .parameters
                    .next(T.self) as! Future<T>)
                    .delete(on: request)
                    .transform(to: .ok)
            }
        }
        if operationsSelector.contains(.update) {
            router.put(T.self, at: "/") { (request, content) -> Future<HTTPStatus> in
                return content
                    .update(on: request)
                    .transform(to: .ok)
            }
        }
    }
}
