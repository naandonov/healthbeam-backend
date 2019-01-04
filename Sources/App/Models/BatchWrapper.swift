//
//  BatchWrapper.swift
//  App
//
//  Created by Nikolay Andonov on 24.12.18.
//

import Foundation
import Vapor
import FluentPostgreSQL

final class BatchWrapper<T: Content>: Content {
    
    let currentPage: Int
    let elementsInPage: Int
    let totalPagesCount: Int
    let totalElementsCount: Int
    
    let items: [T]
    
    init(currentPage: Int, elementsInPage: Int, totalPagesCount: Int, totalElementsCount: Int, items: [T]) {
        self.currentPage = currentPage
        self.elementsInPage = elementsInPage
        self.totalPagesCount = totalPagesCount
        self.totalElementsCount = totalElementsCount
        self.items = items
    }
    
}
