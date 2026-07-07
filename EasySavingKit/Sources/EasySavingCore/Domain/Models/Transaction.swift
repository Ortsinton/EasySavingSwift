//
//  Transaction.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 7/7/26.
//

import Foundation

public struct Transaction : Sendable, Identifiable, Hashable {
    public struct ID: Sendable, Hashable {
        let uuid: UUID
    }
    
    public enum Kind: Sendable, Hashable {
        case income
        case expense
    }
    
    public let id: ID
    public let type: Kind
    public let amount: Money
    public let categoryID: Category.ID
    public let note: String
    public let date: Date
    public let createdAt: Date
    
    /*public init(id: TransactionID,
                type: TransactionType,
                amount: Money,
                categoryID: Category.CategoryID,
                description: String,
                date: Date,
                createdAt: Date,
                calendar: Calendar) {
        self.id = id
        self.type = type
        self.amount = amount
        self.categoryID = categoryID
        self.description = description
        self.date = calendar.startOfDay(for: date)
        self.createdAt = createdAt
    }*/
}
