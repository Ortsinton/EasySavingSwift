//
//  TransactionModel.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 9/7/26.
//

import Foundation
import SwiftData

@Model
final class TransactionModel {
    @Attribute(.unique) var id: UUID
    var amountMinorUnits: Int
    var categoryID: UUID
    var currencyCode: String
    var kind: String
    var note: String?
    var date: Date
    var createdAt: Date

    init(
        id: UUID,
        amountMinorUnits: Int,
        categoryID: UUID,
        currencyCode: String,
        kind: String,
        note: String?,
        date: Date,
        createdAt: Date,
    ) {
        self.id = id
        self.amountMinorUnits = amountMinorUnits
        self.categoryID = categoryID
        self.currencyCode = currencyCode
        self.kind = kind
        self.note = note
        self.date = date
        self.createdAt = createdAt
    }
}
