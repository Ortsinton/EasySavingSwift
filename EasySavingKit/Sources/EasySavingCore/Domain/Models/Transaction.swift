//
//  Transaction.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 7/7/26.
//

import Foundation

public struct Transaction: Sendable, Identifiable, Hashable {
    public struct ID: Sendable, Hashable {
        public let rawValue: UUID

        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }

    public enum Kind: Sendable, Hashable {
        case income
        case expense
    }

    public let id: ID
    public let kind: Kind
    public let amount: Money
    public let categoryID: Category.ID
    public let note: String?
    public let date: Date
    public let createdAt: Date

    public init(id: ID,
                kind: Kind,
                amount: Money,
                categoryID: Category.ID,
                note: String?,
                date: Date,
                createdAt: Date,
                calendar: Calendar)
    {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.categoryID = categoryID
        self.note = note
        self.date = calendar.startOfDay(for: date)
        self.createdAt = createdAt
    }
}
