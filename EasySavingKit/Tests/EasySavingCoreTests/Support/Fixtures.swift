//
//  Fixtures.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 8/7/26.
//

import EasySavingCore
import Foundation

enum Fixtures {
    /// Fixed calendar: the domain rule is "the *injected* calendar decides
    /// the day" — tests pin one explicitly, never the machine's.
    static let madridCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }()

    /// Builds a Date from literal components through the pinned calendar —
    /// the independent origin for expected values.
    static func date(_ year: Int, _ month: Int, _ day: Int,
                     _ hour: Int = 0, _ minute: Int = 0) -> Date
    {
        madridCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    /// Test-data builder: defaults for everything irrelevant to the date
    /// contract, so each test states only what it cares about.
    static func makeTransaction(id: Transaction.ID = Transaction.ID(),
                                kind: Transaction.Kind = .expense,
                                amount: Money = Money(minorUnits: 1000, currencyCode: "EUR"),
                                categoryID: EasySavingCore.Category.ID = Category.ID(),
                                note: String? = nil,
                                date: Date = date(2026, 1, 1),
                                createdAt: Date = date(2026, 1, 1)) -> Transaction
    {
        Transaction(
            id: id,
            kind: kind,
            amount: amount,
            categoryID: categoryID,
            note: note,
            date: date,
            createdAt: createdAt,
            calendar: madridCalendar,
        )
    }

    static func makeCategory(id: EasySavingCore.Category.ID = Category.ID(),
                             name: String = "Test",
                             iconKey: String = "",
                             colorKey: String = "") -> EasySavingCore.Category
    {
        Category(id: id, name: name, iconKey: iconKey, colorKey: colorKey)
    }
}
