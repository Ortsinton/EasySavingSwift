//
//  TransactionTests.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 7/7/26.
//

import EasySavingCore
import Foundation
import Testing

struct TransactionTests {
    @Test(arguments: [
        // (input: y, m, d, h, min)         (expected midnight: y, m, d)
        (input: (2026, 7, 15, 14, 30), expected: (2026, 7, 15)), // afternoon → same-day midnight
        (input: (2026, 7, 15, 0, 0), expected: (2026, 7, 15)), // midnight is a fixed point
        (input: (2026, 7, 15, 23, 59), expected: (2026, 7, 15)), // last minute never jumps day
        (input: (2026, 3, 29, 3, 30), expected: (2026, 3, 29)), // DST: 02:00–03:00 doesn't exist in Madrid
    ])
    func `business date is normalized to start of day in the injected calendar`
    (input: (Int, Int, Int, Int, Int), expected: (Int, Int, Int)) {
        let transaction = Fixtures.makeTransaction(date: Fixtures.date(input.0, input.1, input.2, input.3, input.4))
        #expect(transaction.date == Fixtures.date(expected.0, expected.1, expected.2))
    }

    @Test(arguments: [
        // (a: y, m, d, h, min)         (b: y, m, d, h, min)
        (a: (2026, 3, 29, 14, 30), b: (2026, 3, 30, 3, 15)), // Daylight saving correlative days
    ])
    func `spring-forward day lasts 23 hours through the injected calendar`
    (a: (Int, Int, Int, Int, Int), b: (Int, Int, Int, Int, Int)) {
        let firstTransaction = Fixtures.makeTransaction(date: Fixtures.date(a.0, a.1, a.2, a.3, a.4))
        let secondTransaction = Fixtures.makeTransaction(date: Fixtures.date(b.0, b.1, b.2, b.3, b.4))
        #expect(secondTransaction.date.timeIntervalSince(firstTransaction.date) == 82800)
    }

    @Test
    func `createdAt values are not normalized`() {
        let nonNormalizedDate = Fixtures.date(2026, 3, 29, 14, 30)
        let firstTransaction = Fixtures.makeTransaction(createdAt: nonNormalizedDate)
        #expect(firstTransaction.createdAt == nonNormalizedDate)
    }
}
