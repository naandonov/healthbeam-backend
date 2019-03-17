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
    
    func simpleDateString() -> String {
        return DateFormatter.simpleDateFormatter.string(from: self)
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
    
    fileprivate static let simpleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter
    }()
}
