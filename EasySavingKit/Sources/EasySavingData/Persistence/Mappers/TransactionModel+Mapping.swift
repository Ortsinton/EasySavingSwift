//
//  TransactionModel+Mapping.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 10/7/26.
//

import EasySavingCore

extension TransactionModel {
    private enum KindValue {
        static let income = "income"
        static let expense = "expense"
    }

    convenience init(from transaction: Transaction) {
        self.init(
            id: transaction.id.rawValue,
            amountMinorUnits: transaction.amount.minorUnits,
            categoryID: transaction.categoryID.rawValue,
            currencyCode: transaction.amount.currencyCode,
            kind: TransactionModel.kindStringValue(from: transaction.kind),
            note: transaction.note,
            date: transaction.date,
            createdAt: transaction.createdAt,
        )
    }

    func toDomain() throws -> Transaction {
        try Transaction(
            id: Transaction.ID(rawValue: id),
            kind: TransactionModel.kind(from: kind),
            amount: Money(minorUnits: amountMinorUnits, currencyCode: currencyCode),
            categoryID: Category.ID(rawValue: categoryID),
            note: note,
            normalizedDate: date,
            createdAt: createdAt,
        )
    }

    func update(from transaction: Transaction) {
        precondition(id == transaction.id.rawValue,
                     "update(from:) called with mismatched id: expected model \(id), got transaction \(transaction.id)")
        kind = Self.kindStringValue(from: transaction.kind)
        amountMinorUnits = transaction.amount.minorUnits
        currencyCode = transaction.amount.currencyCode
        note = transaction.note
        categoryID = transaction.categoryID.rawValue
        date = transaction.date
        createdAt = transaction.createdAt
    }

    private static func kindStringValue(from kind: Transaction.Kind) -> String {
        switch kind {
        case .income: KindValue.income
        case .expense: KindValue.expense
        }
    }

    private static func kind(from string: String) throws -> Transaction.Kind {
        switch string {
        case KindValue.income: .income
        case KindValue.expense: .expense
        default: throw MappingError.unknownTransactionKind(string)
        }
    }
}
