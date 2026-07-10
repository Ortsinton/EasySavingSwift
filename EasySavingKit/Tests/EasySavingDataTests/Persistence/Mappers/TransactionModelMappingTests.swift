//
//  TransactionModelMappingTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 10/7/26.
//

import Testing
@testable import EasySavingData
import EasySavingCore
import Foundation

@Suite
struct TransactionModelMappingTests {
    
    @Test(arguments: [
        (Transaction.Kind.income, "income", "A test transaction"),
        (Transaction.Kind.expense, "expense", nil)
    ])
    func `transaction round trip provides the exact same fields`(
        expectedKind: Transaction.Kind,
        expectedKindString: String,
        expectedNote: String?
    ) throws {
        let expectedId = UUID()
        let expectedNotNormalizedDate = Fixtures.date(2020, 1, 1, 21, 30)
        let expectedAmountMinorUnits = 10
        let expectedCurrency = "USD"
        let expectedCategoryID = UUID()
        let expectedCreatedAt = Fixtures.date(2020, 1, 1, 8, 15)
        
        let transaction = Fixtures.makeTransaction(
            id: Transaction.ID(rawValue: expectedId),
            kind: expectedKind,
            amount: Money(minorUnits: expectedAmountMinorUnits, currencyCode: expectedCurrency),
            categoryID: Category.ID(rawValue: expectedCategoryID),
            note: expectedNote,
            date: expectedNotNormalizedDate,
            createdAt: expectedCreatedAt
            )
        
        let model = TransactionModel(from: transaction)
        
        #expect(model.id == transaction.id.rawValue)
        #expect(model.kind == expectedKindString)
        #expect(model.amountMinorUnits == transaction.amount.minorUnits)
        #expect(model.currencyCode == transaction.amount.currencyCode)
        #expect(model.categoryID == transaction.categoryID.rawValue)
        #expect(model.note == transaction.note)
        #expect(model.date == transaction.date)
        #expect(model.createdAt == transaction.createdAt)
        
        let actualTransaction = try model.toDomain()
        
        #expect(actualTransaction == transaction)
    }
    
    @Test
    func `transaction date is always normalized according to the provided calendar's midnight`() throws {
        let date = Fixtures.date(2026, 3, 15, 17, 45)
        let expectedDate = Fixtures.madridCalendar.startOfDay(for: date)
        
        let transaction = Fixtures.makeTransaction(date: date)
        let model = TransactionModel(from: transaction)
        let actualTransaction = try model.toDomain()
        
        #expect(actualTransaction.date == expectedDate)
    }
    
    @Test
    func `providing an unexpected transaction kind to a model throws a MappingError when mapping to domain`() throws {
        let model = TransactionModel(
            id: UUID(),
            amountMinorUnits: 1000,
            categoryID: UUID(),
            currencyCode: "EUR",
            kind: "banana",
            note: nil,
            date: Fixtures.date(2020, 1, 1, 21, 30),
            createdAt: Fixtures.date(2020, 1, 1, 23, 0)
            )
        
        #expect(throws: MappingError.unknownTransactionKind("banana")) {
            try model.toDomain()
        }
    } 
}
