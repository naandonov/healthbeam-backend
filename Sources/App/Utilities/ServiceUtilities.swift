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

protocol PublicMapper {
    associatedtype PublicElement: Content
    func mapToPublic() throws -> PublicElement
}
struct QueryCount: Content {
    let count: Int
}

enum BatchQueryConfiguration {
    case searchQuery(keyName: String)
    case sort(keyName: String, isAscending: Bool)
    case filter(keyValuePairs: [String: String])
}

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
                if requireAuthorization {
                    _ = try request.requireAuthenticated(User.self)
                }
                return content
                    .update(on: request)
                    .transform(to: .ok)
            }
        }
    }
    
    class func generateBatchOperation<T: CRUDModelProvider>(router: Router, type: T.Type, elementsInPage: Int = 20, userFilterClosure: ((User) -> [BatchQueryConfiguration])? = nil) where T: PublicMapper {
        router.get() { request -> Future<BatchWrapper<T.PublicElement>> in
            let user = try request.requireAuthenticated(User.self)
            
            let tableName = String(describing: T.self)
            var searchQuery = " FROM \"\(tableName)\""
            
            var queryConfigurations: [BatchQueryConfiguration] = []
            if let userFilterClosure = userFilterClosure {
                queryConfigurations += userFilterClosure(user)
            }
            
            for configuration in queryConfigurations {
                switch configuration {
                    
                case let .searchQuery(keyName):
                    if let searchParameter = request.query[String.self, at: "search"] {
                        searchQuery += " WHERE LOWER(\"\(keyName)\") LIKE LOWER('%\(searchParameter)%')"
                    }
                case .filter(let keyValuePairs):
                    var appendStatement: String
                    if searchQuery.contains("WHERE") {
                        appendStatement = " AND"
                    }
                    else {
                        appendStatement = " WHERE"
                    }
                    for (key, value) in keyValuePairs {
                        searchQuery += "\(appendStatement) \"\(key)\" = '\(value)'"
                        appendStatement = "AND"
                    }
                case let .sort(keyName, isAscending):
                    searchQuery += " ORDER BY (\"\(keyName)\") \(isAscending ? "ASC" : "DESC")"
                }
            }
            
            let countQuery = "SELECT COUNT(id)" + searchQuery
            var resultsQuery = "SELECT *" + searchQuery
            
            return request.withNewConnection(to: .psql) { connection in
                return connection
                    .raw(countQuery)
                    .first(decoding: QueryCount.self)
                } .flatMap { valueWrapper in
                    
                    guard let elementsCount = valueWrapper?.count else {
                        return Future.map(on: request) {
                            return BatchWrapper(currentPage: 0,
                                                elementsInPage: 0,
                                                totalPagesCount: 0,
                                                totalElementsCount: 0,
                                                result: [])
                        }
                    }
                    
                    let pagesCount = Int(ceil(Double(elementsCount)/Double(elementsInPage)))
                    var currentPage = 1
                    if let pageQuery = request.query[Int.self, at: "page"] {
                        currentPage = pageQuery
                    }
                    let rangeStart = (currentPage - 1) * elementsInPage
                    resultsQuery += " LIMIT \(elementsInPage) OFFSET \(rangeStart)"
                    
                    return request.withNewConnection(to: .psql) { connection in
                        return connection
                            .raw(resultsQuery)
                            .all(decoding: T.self)
                        }.map { elements in
                            
                            let result = try elements.map {
                                try $0.mapToPublic()
                            }
                            
                            return BatchWrapper(currentPage: currentPage,
                                                elementsInPage: elements.count,
                                                totalPagesCount: pagesCount,
                                                totalElementsCount: elementsCount,
                                                result: result)
                    }
            }
        }
    }
    
    class func pushToDeviceToken(_ token: String, _ payload: APNSPayload, _ req: Request) throws -> Future<HTTPStatus> {
        
        let shell = try req.make(Shell.self)
        
        let certURL = FileManager.shared.pushCertificateURL()
        let apnsURL: String
        if Environment.IS_PRODUCTION_ENVIRONMENT {
            apnsURL = "https://api.push.apple.com/3/device/"
        }
        else {
            apnsURL =  "https://api.development.push.apple.com/3/device/"
        }
        let password = Environment.PUSH_CERTIFICATE_PWD
        let bundleId = Environment.BUNDLE_IDENTIFIER
        
        let content = APNSPayloadContent(payload: payload)
        let data = try JSONEncoder().encode(content)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw Abort(.custom(code: 512, reasonPhrase: "Invalid APNS payload"))
        }
        
        let arguments = ["-d", jsonString, "-H", "apns-topic:\(bundleId)", "-H", "apns-expiration: 1", "-H", "apns-priority: 10", "--http2", "--cert", "\(certURL.relativePath):\(password)", apnsURL + token]
        
        return try shell.execute(commandName: "curl", arguments: arguments).map(to: HTTPStatus.self) { data in
            print(data)
            return .ok
        }
        
    }
}
