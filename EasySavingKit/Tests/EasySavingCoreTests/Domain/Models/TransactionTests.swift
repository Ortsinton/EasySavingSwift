//
//  TransactionTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 7/7/26.
//

import Testing
import EasySavingCore
import Foundation

struct TransactionTests {
    /// Fixed calendar: the domain rule is "the *injected* calendar decides
    /// the day" — tests pin one explicitly, never the machine's.
    private static let madridCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }()
    
    /// Builds a Date from literal components through the pinned calendar —
    /// the independent origin for expected values.
    private static func date(_ year: Int, _ month: Int, _ day: Int,
                             _ hour: Int = 0, _ minute: Int = 0) -> Date {
        madridCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
    
    /// Test-data builder: defaults for everything irrelevant to the date
    /// contract, so each test states only what it cares about.
    private static func makeTransaction(date: Date = date(2026, 1, 1), createdAt: Date = date(2026, 1, 1)) -> Transaction {
        Transaction(
            id: Transaction.ID(),
            kind: .expense,
            amount: Money(minorUnits: 1000, currencyCode: "EUR"),
            categoryID: Category.ID(),
            note: nil,
            date: date,
            createdAt: createdAt,
            calendar: madridCalendar)
    }
    
    
    
    @Test(arguments: [
        // (input: y, m, d, h, min)         (expected midnight: y, m, d)
        (input: (2026, 7, 15, 14, 30), expected: (2026, 7, 15)),  // afternoon → same-day midnight
        (input: (2026, 7, 15, 0, 0),   expected: (2026, 7, 15)),  // midnight is a fixed point
        (input: (2026, 7, 15, 23, 59), expected: (2026, 7, 15)),  // last minute never jumps day
        (input: (2026, 3, 29, 3, 30),  expected: (2026, 3, 29)),  // DST: 02:00–03:00 doesn't exist in Madrid
    ])
    func `business date is normalized to start of day in the injected calendar`(input: (Int,Int,Int,Int,Int), expected: (Int,Int,Int)) {
        
        let transaction = Self.makeTransaction(date: Self.date(input.0, input.1, input.2, input.3, input.4))
        #expect(transaction.date == Self.date(expected.0, expected.1, expected.2))
    }
    
    @Test(arguments: [
        // (a: y, m, d, h, min)         (b: y, m, d, h, min)
        (a: (2026, 3, 29, 14, 30), b: (2026, 3, 30, 3, 15)),  // Daylight saving correlative days
    ])
    func `spring-forward day lasts 23 hours through the injected calendar`(a: (Int,Int,Int,Int,Int), b: (Int,Int,Int,Int,Int)) {
        
        let firstTransaction = Self.makeTransaction(date: Self.date(a.0, a.1, a.2, a.3, a.4))
        let secondTransaction = Self.makeTransaction(date: Self.date(b.0, b.1, b.2, b.3, b.4))
        #expect(secondTransaction.date.timeIntervalSince(firstTransaction.date) == 82_800)
    }
    
    @Test
    func `createdAt values are not normalized`() {
        let nonNormalizedDate = Self.date(2026, 3, 29, 14, 30)
        let firstTransaction = Self.makeTransaction(createdAt: nonNormalizedDate)
        #expect(firstTransaction.createdAt == nonNormalizedDate)
    }
}
