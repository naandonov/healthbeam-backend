import Vapor
import Crypto

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let clientRootController = ClientRootController()
    try router.register(collection: clientRootController)
    
    let webRootController = WebRootController()
    try router.register(collection: webRootController)
    
}
