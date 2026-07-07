//
//  Money.swift
//  EasySavingKit
//
//  Created by Jorge Sirvent on 7/7/26.
//

public struct Money: Sendable, Hashable {
    public let minorUnits: Int
    public let currencyCode: String // ISO 4217 -> "EUR" / "USD" / "GBP"

    public init(minorUnits: Int, currencyCode: String) {
        self.minorUnits = minorUnits
        self.currencyCode = currencyCode
    }

    /// Both operands must share the same currency; mixing currencies is a programmer error and traps at runtime.
    public static func + (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currencyCode == rhs.currencyCode, "Cannot add Money from different currencies")

        return Money(minorUnits: lhs.minorUnits + rhs.minorUnits, currencyCode: lhs.currencyCode)
    }

    /// Both operands must share the same currency; mixing currencies is a programmer error and traps at runtime.
    public static func - (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currencyCode == rhs.currencyCode, "Cannot subtract Money from different currencies")

        return Money(minorUnits: lhs.minorUnits - rhs.minorUnits, currencyCode: lhs.currencyCode)
    }

    /// Returns a value with the same currency and the amount multiplied by the scalar
    public static func * (lhs: Money, scalar: Int) -> Money {
        Money(minorUnits: lhs.minorUnits * scalar, currencyCode: lhs.currencyCode)
    }

    /// Returns a value with the same currency and the amount negated.
    public static prefix func - (money: Money) -> Money {
        Money(minorUnits: -money.minorUnits, currencyCode: money.currencyCode)
    }
}
