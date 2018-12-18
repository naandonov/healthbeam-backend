import Vapor
import Crypto

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let directory = DirectoryConfig.detect()
    let configDir = "Resources"
    
        let publicKeyData = try Data(contentsOf: URL(fileURLWithPath: directory.workDir)
            .appendingPathComponent(configDir, isDirectory: true)
            .appendingPathComponent("publicKey.key", isDirectory: false))
    
    let privateKeyData = try Data(contentsOf: URL(fileURLWithPath: directory.workDir)
        .appendingPathComponent(configDir, isDirectory: true)
        .appendingPathComponent("privateKey.key", isDirectory: false))
    
    let encryptedData = try RSA.encrypt("vapor", key: .public(pem: publicKeyData))
    
    let decryptedData = try RSA.decrypt(encryptedData, key: .private(pem: privateKeyData))

    
    let clientRootController = ClientRootController()
    try router.register(collection: clientRootController)
    
    let webRootController = WebRootController()
    try router.register(collection: webRootController)
    
}
