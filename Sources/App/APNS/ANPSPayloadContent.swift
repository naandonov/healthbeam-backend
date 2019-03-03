//
//  PayloadContent.swift
//  APNS
//

import Foundation
import Vapor

struct Alert: Content {
    enum CodingKeys: String, CodingKey {
        case title = "title"
        case subtitle = "subtitle"
        case body = "body"
        
        case titleLocKey = "title-loc-key"
        case titleLocArgs = "title-loc-args"
        
        case actionLocKey = "action-loc-key"
        
        case bodyLocKey = "body-loc-key"
        case bodyLocArgs = "body-loc-args"
        
        case launchImage = "launch-image"
    }
    var title: String?
    var subtitle: String?
    var body: String?
    var titleLocKey: String?
    var titleLocArgs: [String]?
    var actionLocKey: String?
    var bodyLocKey: String?
    var bodyLocArgs: [String]?
    var launchImage: String?
}

struct APS: Content {
    var alert: Alert
    var badge: Int?
    var sound: String?
    var category: String?
    var contentAvailable: Bool = false
    var hasMutableContent: Bool = false
}

struct APNSPayloadContent: Content {
    var aps: APS
    var threadId: String?
    var extra: [String : String] = [:]
    
    init(payload: APNSPayload) {
        let alert = Alert(
            title: payload.title,
            subtitle: payload.subtitle,
            body: payload.body,
            titleLocKey: payload.titleLocKey,
            titleLocArgs: payload.titleLocArgs,
            actionLocKey: payload.actionLocKey,
            bodyLocKey: payload.bodyLocKey,
            bodyLocArgs: payload.bodyLocArgs,
            launchImage: payload.launchImage
        )
        self.aps = APS(
            alert: alert,
            badge: payload.badge,
            sound: payload.sound,
            category: payload.category,
            contentAvailable: payload.contentAvailable,
            hasMutableContent: payload.hasMutableContent
        )
        self.threadId = payload.threadId
        self.extra = payload.extra
    }
}
