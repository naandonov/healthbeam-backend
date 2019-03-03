//
//  FileManager.swift
//  App
//
//  Created by Nikolay Andonov on 19.12.18.
//

import Foundation
import Vapor


final class FileManager {
    
    static let shared = FileManager()
    private init() {}
    
    private let directory = DirectoryConfig.detect()
    
    func publicKeyContent() throws -> Data {
       return try Data(contentsOf: URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("publicKey.pem", isDirectory: false))
    }
    
    func privateKeyContent() throws -> Data {
        return try Data(contentsOf: URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("privateKey.pem", isDirectory: false))
    }
    
    func pushCertificateURL()  -> URL? {
        if Environment.IS_PRODUCTION_ENVIRONMENT {
            //TODO: Add separate production certificate
            return URL(fileURLWithPath: directory.workDir)
                .appendingPathComponent("Resources", isDirectory: true)
                .appendingPathComponent("aps_development.pem", isDirectory: false)
        } else if Environment.IS_STAGING_ENVIRONMENT {
            return URL(fileURLWithPath: directory.workDir)
                .appendingPathComponent("Resources", isDirectory: true)
                .appendingPathComponent("aps_development.pem", isDirectory: false)
        }
        return nil
    }
}
