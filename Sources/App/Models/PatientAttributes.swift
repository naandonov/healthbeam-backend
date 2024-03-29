//
//  PatientAttributes.swift
//  App
//
//  Created by Nikolay Andonov on 4.01.19.
//

import Foundation
import Vapor

struct PatientAttributes: Content {
    
    let observers: [User.ExternalPublic]
    let healthRecords: [HealthRecord.Public]
    let patientTag: PatientTag.Public?
}
