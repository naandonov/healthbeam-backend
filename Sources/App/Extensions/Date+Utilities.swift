//
//  Date+Utilities.swift
//  App
//
//  Created by Nikolay Andonov on 15.12.18.
//

import Foundation

extension Date {
    
    func extendedDateString() -> String {
        return DateFormatter.extendedDateFormatter.string(from: self)
    }
    
    func yearsSince() -> String {
        return "\(Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0)"
    }
}

extension DateFormatter {
    
    fileprivate static let extendedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
